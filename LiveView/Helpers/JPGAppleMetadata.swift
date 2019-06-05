//
// JPGAppleMetadata.swift
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

import MobileCoreServices

public enum JPGAppleMetadata {
    private enum AppleConstants {
        static let appleMarketNote = "17"
    }

    static func injectToFile(at sourcePath: String, output fileAsset: FileAsset) throws {
        let sourceImageUrl = URL(fileURLWithPath: sourcePath)
        let newImageUrl = URL(fileURLWithPath: fileAsset.path)

        guard let initialImageData = try? Data(contentsOf: sourceImageUrl) else {
            throw LKError.invalidFilePath(filePath: sourcePath)
        }

        guard let newImage = CGImageDestinationCreateWithURL(newImageUrl as CFURL, kUTTypeJPEG, 1, nil) else {
            throw LKError.invalidFilePath(filePath: newImageUrl.path)
        }

        guard let imageSource = CGImageSourceCreateWithData(initialImageData as CFData, nil),
              var metadata = CGImageSourceCopyProperties(imageSource, nil) as? [AnyHashable: AnyHashable] else {
            throw LKError.invalidFileMetadata(filePath: sourcePath)
        }

        let markerNote = [AppleConstants.appleMarketNote: fileAsset.identifier]
        let exifVersion = [kCGImagePropertyExifVersion: [2, 2, 1]]

        metadata[kCGImagePropertyMakerAppleDictionary] = markerNote
        metadata[kCGImagePropertyExifDictionary] = exifVersion

        CGImageDestinationAddImageFromSource(newImage, imageSource, 0, metadata as CFDictionary)
        CGImageDestinationFinalize(newImage)
    }
}
