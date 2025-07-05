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
    let amountToSend: Decimal
    let destination: String
    let tag: String?
    let walletModel: any WalletModel
}
