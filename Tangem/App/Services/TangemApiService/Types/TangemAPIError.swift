//
//  TangemAPIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TangemAPIError: Decodable, Error, LocalizedError {
    let code: ErrorCode
    let description: String?

    var errorDescription: String? {
        description ?? code.description
    }

    init(code: TangemAPIError.ErrorCode, description: String? = nil) {
        self.code = code
        self.description = description
    }
}

extension TangemAPIError {
    enum ErrorCode: Int, Decodable {
        case unknown = -1
        case decode

        case notFound = 404

        /// The description for local errors
        var description: String? {
            switch self {
            case .notFound:
                return nil
            case .decode:
                return "Decoding error"
            case .unknown:
                return "Unknown error"
            }
        }
    }
}
