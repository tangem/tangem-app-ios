//
//  SolanaSendError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

public enum SolanaSendError: Error {
    case alreadyProcessed
    case programError(code: UInt32, logs: [String])
}

extension SolanaSendError {
    /// `ResponseErrorData` keeps only the logs, never the typed `err`, so both answers are read out of the
    /// preflight message. A node words it that way only while it still holds the signature, which is the
    /// window the library's own retry of a lost response falls in.
    static func mapped(from error: any Error) -> any Error {
        guard let response = responseError(from: error), let message = response.message else {
            return error
        }

        if message.localizedCaseInsensitiveContains(Constants.alreadyProcessedMarker) {
            return SolanaSendError.alreadyProcessed
        }

        if let code = programErrorCode(message: message) {
            return SolanaSendError.programError(code: code, logs: response.data?.logs ?? [])
        }

        return error
    }

    /// The router raises `RPCError`; only paths that already hold a `SolanaError` re-wrap it as one.
    private static func responseError(from error: any Error) -> ResponseError? {
        if case RPCError.invalidResponse(let response) = error {
            return response
        }

        if case SolanaError.invalidResponse(let response) = error {
            return response
        }

        return nil
    }

    /// Reads `custom program error: 0x1774` — hexadecimal, no fixed width.
    private static func programErrorCode(message: String) -> UInt32? {
        guard let range = message.range(of: Constants.customErrorMarker, options: .caseInsensitive) else {
            return nil
        }

        let digits = message[range.upperBound...].prefix { $0.isHexDigit }

        return UInt32(digits, radix: 16)
    }

    private enum Constants {
        static let alreadyProcessedMarker = "already been processed"
        static let customErrorMarker = "custom program error: 0x"
    }
}
