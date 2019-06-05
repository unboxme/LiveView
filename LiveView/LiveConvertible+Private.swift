//
// PathConvertible+Private.swift
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

import CoreServices

extension PathConvertible {
    var pathError: LKError {
        return LKError.invalidFilePath(filePath: self)
    }
}

extension PathConvertible {
    func validateAsJPG() throws -> Self {
        return try conformsTo(typeIdentifier: kUTTypeJPEG)
    }

    func validateAsMOV() throws -> Self {
        return try conformsTo(typeIdentifier: kUTTypeQuickTimeMovie)
    }

    private func conformsTo(typeIdentifier: CFString) throws -> Self {
        let filePath = try asPath()
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension as CFString

        if let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil),
           UTTypeConformsTo((type.takeRetainedValue()), typeIdentifier) {
            return self
        }

        throw LKError.invalidFileType(filePath: self, expectedType: typeIdentifier as String)
    }
}