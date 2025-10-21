//
//  NFTNavigationInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

struct NFTNavigationInput: NFTNavigationContext {
    let userWalletModel: UserWalletModel
    let name: String
    let walletModelsManager: WalletModelsManager
}
