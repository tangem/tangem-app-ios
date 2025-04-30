//
//  NFTReceiveInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

struct NFTReceiveInput: NFTEntrypointNavigationContext {
    let userWalletName: String
    let userWalletConfig: UserWalletConfig
    let walletModelsManager: WalletModelsManager
}
