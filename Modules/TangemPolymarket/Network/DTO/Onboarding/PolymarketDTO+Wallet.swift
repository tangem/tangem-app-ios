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
        let status: PolymarketDepositWalletStatus
    }

    struct WalletOperationResponse: Decodable {
        let status: PolymarketDepositWalletStatus
    }

    struct DeployRequest: Encodable {
        let ownerAddress: String
        let depositWalletAddress: String
        let walletId: String
    }
}
