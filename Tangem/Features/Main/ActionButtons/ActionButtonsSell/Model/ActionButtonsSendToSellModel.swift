//
//  ActionButtonsSendToSellModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsSendToSellModel {
    let sellParameters: PredefinedSellParameters
    let walletModel: any WalletModel
}
