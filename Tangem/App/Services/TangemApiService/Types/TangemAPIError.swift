//
//  TangemAPIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TangemBaseAPIError: Decodable {
    let error: TangemAPIError
}

struct TangemAPIError: Decodable, Error, LocalizedError {
    let code: ErrorCode
    let message: String?

    var errorDescription: String? {
        message ?? code.description
    }

    init(code: TangemAPIError.ErrorCode, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

extension TangemAPIError {
    enum ErrorCode: Int, Decodable {
        // Internal errors
        case unknown = -1
        case decode = -2

        // Server-side errors

        // Promotion
        case promotionCodeNotFound = 101
        case promotionCodeNotApplied = 102
        case promotionCodeAlreadyUsed = 103
        case promotionWalletAlreadyAwarded = 104
        case promotionCardAlreadyAwarded = 105

        // Misc
        case notFound = 404

        /// The description for local errors, for server errors description will be gotten from api
        var description: String? {
            switch self {
            case .notFound, .promotionCodeNotFound, .promotionCodeNotApplied, .promotionCodeAlreadyUsed, .promotionWalletAlreadyAwarded, .promotionCardAlreadyAwarded:
                return nil
            case .decode:
                return "Decoding error"
            case .unknown:
                return "Unknown error"
            }
        }
    }
}
