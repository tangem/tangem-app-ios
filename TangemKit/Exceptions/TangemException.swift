//
//  File.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

enum TangemException: Error {
    case tooMuchHashes
    case notIdenticalHashesLength
    case wrongResponseApdu (description: String)
}

extension TangemException: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .wrongResponseApdu (let description):
            return description
        case .notIdenticalHashesLength:
            return "notIdenticalHashesLength"
        case .tooMuchHashes:
            return "tooMuchHashes"
        }
    }
}
