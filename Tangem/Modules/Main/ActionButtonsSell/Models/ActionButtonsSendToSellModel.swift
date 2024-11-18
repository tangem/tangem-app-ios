//
//  ActionButtonsSendToSellModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsSendToSellModel {
    let amountToSend: Amount
    let destination: String
    let tag: String?
    let walletModel: WalletModel
}
