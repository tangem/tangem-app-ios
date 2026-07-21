//
//  SubtitleOwnerResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemAccounts
import TangemFoundation

struct SubtitleOwnerResolver {
    let blockchain: Blockchain
    let currentUserWalletId: UserWalletId
    let isAccountsMode: Bool

    func resolve(for interactionAddress: TransactionViewModel.InteractionAddressType) -> TransactionViewModel.SubtitleOwner? {
        guard let address = counterpartyAddress(from: interactionAddress) else {
            return nil
        }

        guard let match = try? WalletModelFinder.findMainWalletModel(address: address, blockchain: blockchain) else {
            return .unresolved(
                short: AddressFormatter(address: address).truncated(),
                fullAddress: address,
                blockiesImage: AddressIconProvider.makeBlockiesImage(address: address)
            )
        }

        let walletName = match.userWalletModel.name

        guard isAccountsMode, let account = match.walletModel.account else {
            return .wallet(name: walletName)
        }

        let iconViewData = AccountModelUtils.UI.iconViewData(
            icon: account.icon.erased,
            accountName: account.name
        )

        if match.userWalletModel.userWalletId == currentUserWalletId {
            return .account(name: account.name, icon: iconViewData)
        }

        return .accountInWallet(
            accountName: account.name,
            accountIcon: iconViewData,
            walletName: walletName
        )
    }

    private func counterpartyAddress(from interaction: TransactionViewModel.InteractionAddressType) -> String? {
        switch interaction {
        case .user(let address), .contract(let address):
            return address
        case .multiple, .custom, .staking:
            return nil
        }
    }
}
