//
//  PolymarketDTO+Wallet.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct WalletStatusResponse: Decodable {
        let depositWalletAddress: String?
        let status: PolymarketWalletStatus
    }

    struct WalletOperationResponse: Decodable {
        let status: PolymarketWalletStatus
    }

    struct DeployRequest: Encodable {
        let ownerAddress: String
        let depositWalletAddress: String
        let walletId: String
    }

    struct ApprovalsRequest: Encodable {
        let ownerAddress: String
        let depositWalletAddress: String
        let nonce: String
        let deadline: String
        let calls: [ApprovalCall]
        let signature: String
    }

    struct ApprovalCall: Encodable {
        let target: String
        let value: String
        let data: String
    }
}
