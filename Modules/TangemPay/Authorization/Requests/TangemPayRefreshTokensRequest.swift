//
//  TangemPayRefreshTokensRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayRefreshTokensRequest: Encodable {
    let refreshToken: String

    let authType = "customer_wallet"
}
