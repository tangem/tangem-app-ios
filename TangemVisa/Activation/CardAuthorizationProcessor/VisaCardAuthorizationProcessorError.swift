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
}
