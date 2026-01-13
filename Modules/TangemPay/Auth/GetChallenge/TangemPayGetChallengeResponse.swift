//
//  TangemPayGetChallengeResponse.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayGetChallengeResponse: Decodable {
    public let nonce: String
    public let sessionId: String
}
