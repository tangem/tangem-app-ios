//
//  TangemPayDepositOwner.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemAccounts
import TangemFoundation

struct TangemPayDepositOwner: Equatable {
    let userWalletId: UserWalletId
    let name: String
    let icon: AccountIconView.ViewData
    let entries: [TangemPayAccountTokensResolver.Entry]

    static func make(from userWalletModels: [UserWalletModel]) -> [TangemPayDepositOwner] {
        userWalletModels.compactMap { userWalletModel in
            guard
                let accountModel = AccountModelsAggregator(.tangemPay).model(from: userWalletModel.accountModelsManager),
                let account = accountModel.state?.tangemPayAccount ?? accountModel.lastKnownTangemPayAccount
            else {
                return nil
            }

            let entries = TangemPayAccountTokensResolver.makeEntries(from: account.networks)

            guard entries.isNotEmpty else {
                return nil
            }

            return TangemPayDepositOwner(
                userWalletId: userWalletModel.userWalletId,
                name: accountModel.name,
                icon: AccountModelUtils.UI.iconViewData(accountModel: accountModel),
                entries: entries
            )
        }
    }

    func hasDepositAddress(_ address: String, on blockchain: Blockchain) -> Bool {
        let addressComparator = AddressComparator()

        return entries.contains { entry in
            entry.blockchain.networkId == blockchain.networkId
                && entry.blockchain.isTestnet == blockchain.isTestnet
                && addressComparator.addressesMatch(entry.depositAddress, address, blockchain: blockchain)
        }
    }
}
