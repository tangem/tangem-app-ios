//
//  ActionButtonsSendToSellModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ActionButtonsSendToSellModel {
    let sellParameters: PredefinedSellParameters
    /// The wallet that owns `walletModel`. The token selector lists tokens of every unlocked wallet, so this is not
    /// necessarily the wallet the sell sheet was opened from.
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel
}
