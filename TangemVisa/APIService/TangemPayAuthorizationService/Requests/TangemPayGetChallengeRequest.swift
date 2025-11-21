//
//  TangemPayGetChallengeRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayGetChallengeRequest: Encodable {
    let customerWalletAddress: String

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    let authType = VisaAuthorizationType.customerWallet
}
