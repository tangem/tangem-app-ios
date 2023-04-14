//
//  SwappingProviderError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum SwappingProviderError: LocalizedError {
    case requestError(Error)
    case oneInchError(OneInchError)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .requestError(let error):
            return error.localizedDescription
        case .oneInchError(let inchError):
            return inchError.localizedDescription
        case .decodingError(let error):
            return error.localizedDescription
        }
    }
}
