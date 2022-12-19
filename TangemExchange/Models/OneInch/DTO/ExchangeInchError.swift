//
//  ExchangeProviderError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeProviderError: LocalizedError {
    case requestError(Error)
    case oneInchError(InchError)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .requestError(let error):
            return error.localizedDescription
        case .oneInchError(let inchError):
            return inchError.description
        case .decodingError(let error):
            return error.localizedDescription
        }
    }
}

public struct InchError: Decodable {
    public let statusCode: Int
    public let description: String
    public let requestId: String
}
