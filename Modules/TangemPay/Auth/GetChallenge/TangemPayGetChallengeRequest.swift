//
//  TangemPayGetChallengeRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayGetChallengeRequest: Encodable {
    let customerWalletAddress: String
    let customerWalletId: String

    let authType = "customer_wallet"
}
