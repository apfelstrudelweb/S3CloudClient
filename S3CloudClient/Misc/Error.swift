//
//  Error.swift
//  S3CloudClient
//
//  Created by Ulrich Vormbrock on 02.11.18.
//  Copyright © 2018 Ulrich Vormbrock. All rights reserved.
//

import Foundation

enum S3CloudError: Error {
    case noData(reason: String)
    case wrongStatusCode(reason: String)
    case failedTransfer(reason: String)
}

enum FileError: Error {
    case noElement(reason: String)
    case documentsDirNotExisting(reason: String)
    case subdirNotCreatable(reason: String)
    case fingerpringError(reason: String)
}

enum CoreDataError: Error {
    case noResult(reason: String)
}

private enum ErrorType {
    case nsError(NSError, domain: String, code: Int)
    case swiftLocalizedError(String)
    case swiftError(Mirror.DisplayStyle?)
}


extension Error {
    public var legibleDescription: String {
        switch errorType {
        case .swiftError(.enum?):
            return "\(type(of: self)).\(self)"
        case .swiftError:
            return String(describing: self)
        case .swiftLocalizedError(let msg):
            return msg
        case .nsError(_, "kCLErrorDomain", 0):
            return "The location could not be determined."
        // ^^ Apple don’t provide a localized description for this
        case .nsError(let nsError, _, _):
            if !localizedDescription.hasPrefix("The operation couldn’t be completed.") {
                return localizedDescription
                //FIXME ^^ for non-EN
            } else if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                return underlyingError.legibleDescription
            } else {
                // usually better than the localizedDescription, but not pretty
                return nsError.debugDescription
            }
        }
    }
    
    private var errorType: ErrorType {
        if String(cString: object_getClassName(self)) != "_SwiftNativeNSError" {
            let nserr = self as NSError
            return .nsError(nserr, domain: nserr.domain, code: nserr.code)
        } else if let err = self as? LocalizedError, let msg = err.errorDescription {
            return .swiftLocalizedError(msg)
        } else {
            return .swiftError(Mirror(reflecting: self).displayStyle)
        }
    }
}
