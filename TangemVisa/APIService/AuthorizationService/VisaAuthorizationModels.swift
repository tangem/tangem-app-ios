//
//  VisaAuthorizationModels.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaAuthChallengeResponse: Decodable {
    public let nonce: String
    public let sessionId: String
}

public struct VisaAuthorizationTokens: Decodable {
    public let accessToken: String
    public let refreshToken: String

    // Will be updated in [REDACTED_INFO]. Requirements for activation flow was reworked, so for now this function is for testing purposes
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
