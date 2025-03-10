//
//  CardAuthorizationProcessorError.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum CardAuthorizationProcessorError: TangemError {
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

    public var subsystemCode: Int {
        if case .networkError(let error) = self, let tangemError = error as? TangemError {
            return tangemError.subsystemCode
        }

        return VisaSubsystem.cardAuthoriationProcessor.rawValue
    }

    public var errorCode: Int {
        switch self {
        case .authorizationChallengeNotFound: return 1
        case .invalidCardInput: return 2
        case .networkError(let error):
            if let tangemError = error as? TangemError {
                return tangemError.errorCode
            }

            return 2
        }
    }
}
