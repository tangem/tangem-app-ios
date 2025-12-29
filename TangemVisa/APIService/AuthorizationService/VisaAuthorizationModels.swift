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

public enum VisaAuthorizationType: String, Codable {
    case cardId = "card_id"
    case cardWallet = "card_wallet"
}

public struct VisaAuthorizationTokens: Codable, Equatable {
    public let accessToken: String?
    public let refreshToken: String
    public let authorizationType: VisaAuthorizationType

    public init(accessToken: String?, refreshToken: String, authorizationType: VisaAuthorizationType) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.authorizationType = authorizationType
    }

    init(dto: AuthorizationTokenDTO, authorizationType: VisaAuthorizationType) {
        self.init(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
            authorizationType: authorizationType
        )
    }
}

struct AuthorizationTokenDTO: Codable {
    let accessToken: String?
    let refreshToken: String
}
