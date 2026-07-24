//
//  SubtitleOwnerResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIImage
import BlockchainSdk
import TangemAccounts
import TangemFoundation

struct SubtitleOwnerResolver {
    private static let blockiesImageCache = NSCacheWrapper<String, UIImage>()

    let blockchain: Blockchain
    let currentUserWalletId: UserWalletId
    let isAccountsMode: Bool

    func resolve(for interactionAddress: TransactionViewModel.InteractionAddressType) -> TransactionViewModel.SubtitleOwner? {
        guard let address = counterpartyAddress(from: interactionAddress) else {
            return nil
        }

        guard let match = try? WalletModelFinder.findMainWalletModel(
            address: address,
            networkId: blockchain.networkId,
            isTestnet: blockchain.isTestnet
        ) else {
            return .unresolved(
                short: AddressFormatter(address: address).truncated(),
                fullAddress: address,
                blockiesImage: Self.blockiesImage(for: address)
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
            return .accountInCurrentWallet(name: account.name, icon: iconViewData)
        }

        return .accountInOtherWallet(
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

    private static func blockiesImage(for address: String) -> UIImage? {
        if let cachedImage = blockiesImageCache.value(forKey: address) {
            return cachedImage
        }

        if let newImage = AddressIconProvider.makeBlockiesImage(address: address) {
            blockiesImageCache.setValue(newImage, forKey: address)
            return newImage
        }

        return nil
    }
}
