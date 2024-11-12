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

public struct VisaAccessToken: Decodable {
    public let accessToken: String
    public let refreshToken: String
}
