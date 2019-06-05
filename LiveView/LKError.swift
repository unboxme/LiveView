//
// LKError.swift
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

import Foundation

public enum LKError {
    case nothingToSave
    case liveRequestProblemOccurred(filePaths: [String])
    case invalidImageSource(imageSource: ImageConvertible)
    case invalidFilePath(filePath: PathConvertible)
    case invalidFileType(filePath: PathConvertible, expectedType: String)
    case invalidFile(filePath: String)
    case invalidFileMetadata(filePath: String)

    var localizedDescription: String {
        switch self {
        case .nothingToSave:
            return "There's nothing to save"
        case .liveRequestProblemOccurred(let filePaths):
            return "Couldn't create live resource with paths:\n" + filePaths.joined(separator: "\n")
        case .invalidImageSource(let imageSource):
            return "Couldn't retrieve image from:\n\(imageSource)"
        case .invalidFilePath(let filePath):
            return "Couldn't retrieve file from:\n\(filePath)"
        case .invalidFileType(let filePath, let expectedType):
            return "Couldn't validate as \"\(expectedType)\" file at:\n\(filePath)"
        case .invalidFile(let filePath):
            return "Invalid file at:\n\(filePath)"
        case .invalidFileMetadata(let filePath):
            return "Invalid file metadata at:\n\(filePath)"
        }
    }
}

extension LKError: LocalizedError {
    public var errorDescription: String? {
        return "[\(LiveKit.name)] " + localizedDescription
    }

    public var failureReason: String? {
        return nil
    }

    public var recoverySuggestion: String? {
        return nil
    }

    public var helpAnchor: String? {
        return nil
    }
}