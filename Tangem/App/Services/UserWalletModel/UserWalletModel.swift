//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

protocol UserWalletModel: TotalBalanceProviding, AnyObject {
    var isMultiWallet: Bool { get }
    var tokensCount: Int? { get }
    var userWalletId: UserWalletId { get }
    var userWallet: UserWallet { get }
    var walletModelsManager: WalletModelsManager { get }
    var signer: TangemSigner { get }

    func initialUpdate()
    func updateWalletName(_ name: String)
}
