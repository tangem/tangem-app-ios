//
//  SendSuggestedWalletsFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts

struct SendSuggestedWalletsFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    func makeSuggestedWallets(walletModel: any WalletModel) -> [SendDestinationSuggestedWallet] {
        let ignoredAddresses = walletModel.addresses.map(\.value).toSet()
        let targetNetworkId = walletModel.tokenItem.blockchain.networkId
        let shouldShowAccounts = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple

        let wallets = userWalletRepository.models.flatMap { userWalletModel in
            let walletModels = if FeatureProvider.isAvailable(.accounts) {
                AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
            } else {
                // accounts_fixes_needed_none
                userWalletModel.walletModelsManager.walletModels
            }

            let suggestedWalletModels = walletModels.filter { walletModel in
                let blockchain = walletModel.tokenItem.blockchain
                let sameNetwork = blockchain.networkId == targetNetworkId
                let shouldBeIncluded = { blockchain.supportsCompound || !ignoredAddresses.contains(walletModel.defaultAddressString) }

                return sameNetwork && walletModel.isMainToken && shouldBeIncluded()
            }

            return suggestedWalletModels.map { walletModel in
                let account: SendDestinationSuggestedWallet.Account? = walletModel.account.map { accountModel in
                    let icon = AccountModelUtils.UI.iconViewData(accountModel: accountModel)
                    return .init(icon: icon, name: accountModel.name)
                }

                let tokenHeaderProvider = ExpressInteractorTokenHeaderProvider(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    account: walletModel.account
                )

                return SendDestinationSuggestedWallet(
                    name: userWalletModel.name,
                    address: walletModel.defaultAddressString,
                    account: shouldShowAccounts ? account : .none,
                    accountModelAnalyticsProvider: walletModel.account,
                    tokenHeader: tokenHeaderProvider.makeHeader()
                )
            }
        }

        return wallets
    }
}
