//
//  AccountNFTManagerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import TangemFoundation

protocol AccountNFTManagerFactory {
    func makeNFTManager(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager
    ) -> NFTManager
}
