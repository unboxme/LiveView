//
// LiveResource.swift
//
// Copyright (c) 2019 Puzyrev Pavel
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Photos

public final class LiveResource {

    // MARK: - Private Types

    fileprivate enum Constants {
        static let temporaryImageFileName = "live_resource.jpg"
        static let temporaryMovieFileName = "live_resource.mov"
    }

    // MARK: - Private Properties

    private var asset: LiveAsset?

    // MARK: - Public Methods

    public func requestWith(imageResource: PathConvertible,
                            movieResource: PathConvertible,
                            size: CGSize,
                            completionHandler: @escaping ((PHLivePhoto?, Error?) -> Void)) {
        flush()

        do {
            let imagePath = try imageResource.validateAsJPG().asPath()
            let moviePath = try movieResource.validateAsMOV().asPath()
            let temporaryPath = try FileManager.default.liveResourcesTemporaryPath()

            asset = LiveAsset(path: temporaryPath)

            try JPGAppleMetadata.injectToFile(at: imagePath, output: asset!.imageFile)
            try MOVAppleMetadata.injectToFile(at: moviePath, output: asset!.movieFile)
        } catch {
            completionHandler(nil, error)
        }

        guard let asset = asset else {
            fatalError("Unexpected error occurred while requesting live resource")
        }

        let filePaths = [asset.imageFile.path, asset.movieFile.path]
        let fileURLs = filePaths.map({ URL(fileURLWithPath: $0) })

        let resultHandler: ((PHLivePhoto?, [AnyHashable: Any]) -> Void) = { livePhoto, _ in
            if let livePhoto = livePhoto {
                completionHandler(livePhoto, nil)
            } else {
                let error = LKError.liveRequestProblemOccurred(filePaths: filePaths)
                completionHandler(nil, error)
            }
        }

        PHLivePhoto.request(withResourceFileURLs: fileURLs,
                placeholderImage: nil,
                targetSize: size,
                contentMode: .aspectFit,
                resultHandler: resultHandler)
    }

    public func flush() {
        defer {
            asset = nil
        }

        guard let temporaryPath = try? FileManager.default.liveResourcesTemporaryPath() else {
            return
        }

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: temporaryPath) {
            contents.forEach({ try? FileManager.default.removeItem(atPath: temporaryPath + "/" + $0) })
        }
    }

    public func save(completionHandler: ((Error?) -> Void)?) {
        guard let asset = asset else {
            return
        }

        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, fileURL: URL(fileURLWithPath: asset.imageFile.path), options: nil)
            creationRequest.addResource(with: .pairedVideo, fileURL: URL(fileURLWithPath: asset.movieFile.path), options: nil)
        }, completionHandler: { _, error in
            completionHandler?(error)
        })
    }

}

private extension LiveResource {
    private struct LiveAsset {
        struct File: FileAsset {
            let identifier: String
            let path: String
        }

        let imageFile: File
        let movieFile: File
        let identifier: String

        init(path: String) {
            identifier = UUID().uuidString

            let imagePath = path + "/" + Constants.temporaryImageFileName
            imageFile = File(identifier: identifier, path: imagePath)
            let moviePath = path + "/" + Constants.temporaryMovieFileName
            movieFile = File(identifier: identifier, path: moviePath)
        }
    }
}

fileprivate extension FileManager {
    func liveResourcesTemporaryPath() throws -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let temporaryPath = path + "/" + LiveKit.bundlify("liveResource")

        if !FileManager.default.fileExists(atPath: temporaryPath) {
            try FileManager.default.createDirectory(atPath: temporaryPath, withIntermediateDirectories: true, attributes: nil)
        }

        return temporaryPath
    }
}