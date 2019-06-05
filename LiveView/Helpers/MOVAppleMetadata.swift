//
// MOVAppleMetadata.swift
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

import AVFoundation

public enum MOVAppleMetadata {
    private enum AppleConstants {
        static let contentIdentifier = "com.apple.quicktime.content.identifier"
        static let stillImageTime = "com.apple.quicktime.still-image-time"
        static let quickTimeMetadata = "mdta"
        static let metadataDataTypeUTF8 = "com.apple.metadata.datatype.UTF-8"
        static let metadataDataTypeInt8 = "com.apple.metadata.datatype.int8"
    }

    static func injectToFile(at sourcePath: String, output fileAsset: FileAsset) throws {
        let sourceMovieUrl = URL(fileURLWithPath: sourcePath)
        let sourceMovieAsset = AVURLAsset(url: sourceMovieUrl)
        let newMovieUrl = URL(fileURLWithPath: fileAsset.path)

        guard let videoTrack = sourceMovieAsset.tracks(withMediaType: .video).first else {
            throw LKError.invalidFile(filePath: sourcePath)
        }

        let pixelFormatTypeKey = kCVPixelBufferPixelFormatTypeKey as String
        let readerSettings = [pixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
        let videoReader = try TrackReader(track: videoTrack, asset: sourceMovieAsset, settings: readerSettings)
        let videoWriter = try TrackWriter(track: videoTrack, outputUrl: newMovieUrl, assetIdentifier: fileAsset.identifier)

        // Creating new video with metadata
        videoReader.reader.startReading()
        videoWriter.writer.startWriting()
        videoWriter.writer.startSession(atSourceTime: .zero)
        videoWriter.writeMetadataTrack()

        // Write new video
        let writingQueue = DispatchQueue(label: LiveKit.bundlify("assetVideoWriter"))
        videoWriter.input.requestMediaDataWhenReady(on: writingQueue) {
            while (videoWriter.input.isReadyForMoreMediaData) {
                if videoReader.reader.status == .reading {
                    guard let buffer = videoReader.output.copyNextSampleBuffer(), !videoWriter.input.append(buffer) else {
                        continue
                    }
                    videoReader.reader.cancelReading()
                } else {
                    videoWriter.input.markAsFinished()
                    videoWriter.writer.finishWriting(completionHandler: { })
                }
            }
        }

        // Waiting
        while videoWriter.writer.status == .writing {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        }

        if let error = videoWriter.writer.error {
            throw error
        }
    }
}

private extension MOVAppleMetadata {
    private struct TrackReader {
        let reader: AVAssetReader
        let output: AVAssetReaderTrackOutput

        init(track: AVAssetTrack, asset: AVURLAsset, settings: [String: Any]?) throws {
            output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
            reader = try AVAssetReader(asset: asset)
            reader.add(output)
        }
    }

    private struct TrackWriter {
        let writer: AVAssetWriter
        let input: AVAssetWriterInput
        private let metadataAdaptor: AVAssetWriterInputMetadataAdaptor

        init(track: AVAssetTrack, outputUrl: URL, assetIdentifier: String) throws {
            // Make `input`
            let outputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: track.naturalSize.width,
                AVVideoHeightKey: track.naturalSize.height,
            ]

            input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            input.expectsMediaDataInRealTime = true
            input.transform = track.preferredTransform

            // Make `metadataAdaptor`
            let identifierKey = kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String
            let dataTypeKey = kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String
            let specifications = [
                identifierKey: AppleConstants.quickTimeMetadata + "/" + AppleConstants.stillImageTime,
                dataTypeKey: AppleConstants.metadataDataTypeInt8
            ]

            var formatDescriptionOut: CMFormatDescription?
            CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault,
                    metadataType: kCMMetadataFormatType_Boxed,
                    metadataSpecifications: [specifications] as CFArray,
                    formatDescriptionOut: &formatDescriptionOut)

            let metadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: formatDescriptionOut)
            metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadataInput)

            // Make `writer`
            let metadata = AVMutableMetadataItem()
            metadata.key = AppleConstants.contentIdentifier as NSString
            metadata.keySpace = AVMetadataKeySpace(rawValue: AppleConstants.quickTimeMetadata)
            metadata.dataType = AppleConstants.metadataDataTypeUTF8
            metadata.value = assetIdentifier as NSString

            writer = try AVAssetWriter(outputURL: outputUrl, fileType: .mov)
            writer.metadata = [metadata]
            writer.add(input)
            writer.add(metadataAdaptor.assetWriterInput)
        }

        func writeMetadataTrack() {
            let metadata = AVMutableMetadataItem()
            metadata.key = AppleConstants.stillImageTime as NSString
            metadata.keySpace = AVMetadataKeySpace(rawValue: AppleConstants.quickTimeMetadata)
            metadata.dataType = AppleConstants.metadataDataTypeInt8
            metadata.value = 0 as NSNumber

            let start = CMTimeMake(value: 0, timescale: 1000)
            let duration = CMTimeMake(value: 200, timescale: 3000)
            let timeRange = CMTimeRangeMake(start: start, duration: duration)

            let metadataGroup = AVTimedMetadataGroup(items: [metadata], timeRange: timeRange)
            metadataAdaptor.append(metadataGroup)
        }
    }
}
