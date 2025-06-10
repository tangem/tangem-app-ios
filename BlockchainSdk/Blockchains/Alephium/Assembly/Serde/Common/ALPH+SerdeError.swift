//
//  Alephium+SerdeError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    enum SerdeError: Error, CustomStringConvertible {
        case notEnoughBytes(expected: Int, got: Int)
        case incompleteData(expected: Int, got: Int)
        case redundant(expected: Int, got: Int)
        case validation(message: String)
        case wrongFormat(message: String)
        case other(message: String)

        var description: String {
            switch self {
            case .notEnoughBytes(let expected, let got):
                return "Too few bytes: expected \(expected), got \(got)"
            case .incompleteData(let expected, let got):
                return "Too few bytes: expected \(expected), got \(got)"
            case .redundant(let expected, let got):
                return "Too many bytes: expected \(expected), got \(got)"
            case .validation(let message):
                return "Validation error: \(message)"
            case .wrongFormat(let message):
                return "Wrong format: \(message)"
            case .other(let message):
                return "Other error: \(message)"
            }
        }
    }
}
