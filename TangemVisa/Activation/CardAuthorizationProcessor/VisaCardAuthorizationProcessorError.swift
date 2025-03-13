//
//  VisaCardAuthorizationProcessorError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum VisaCardAuthorizationProcessorError {
    case authorizationChallengeNotFound
    case invalidCardInput
    case networkError(Error)

    public var description: String {
        switch self {
        case .authorizationChallengeNotFound:
            return "Authorization challenge request not found"
        case .invalidCardInput:
            return "Invalid card input"
        case .networkError(let error):
            return "Underlying network error: \(error)"
        }
    }
}
