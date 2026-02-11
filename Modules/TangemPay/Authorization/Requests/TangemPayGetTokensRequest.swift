//
//  TangemPayGetTokensRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayGetTokensRequest: Encodable {
    let signature: String
    let sessionId: String
    let messageFormat: String

    let authType = "customer_wallet"
}
