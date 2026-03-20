//
//  SendSuggestedWalletsFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import TangemAssets
import TangemLocalization

struct SendSuggestedWalletsFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    func makeSuggestedWallets(walletModel: any WalletModel) -> [SendDestinationSuggestedWallet] {
        makeSuggestedWallets(
            targetNetworkId: walletModel.tokenItem.blockchain.networkId,
            ignoredAddresses: walletModel.addresses.map(\.value).toSet(),
            referenceTokenItem: walletModel.tokenItem
        )
    }

    func makeSuggestedWallets(forNetworkId networkId: String) -> [SendDestinationSuggestedWallet] {
        makeSuggestedWallets(
            targetNetworkId: networkId,
            ignoredAddresses: [],
            referenceTokenItem: nil
        )
    }
}

// MARK: - Private

private extension SendSuggestedWalletsFactory {
    func makeSuggestedWallets(
        targetNetworkId: String,
        ignoredAddresses: Set<String>,
        referenceTokenItem: TokenItem?
    ) -> [SendDestinationSuggestedWallet] {
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

            var results = suggestedWalletModels.map { walletModel in
                let account: SendDestinationSuggestedWallet.Account? = walletModel.account.map { accountModel in
                    let icon = AccountModelUtils.UI.iconViewData(accountModel: accountModel)
                    return .init(icon: icon, name: accountModel.name)
                }

                return SendDestinationSuggestedWallet(
                    name: userWalletModel.name,
                    address: walletModel.defaultAddressString,
                    account: shouldShowAccounts ? account : .none,
                    accountModelAnalyticsProvider: walletModel.account
                )
            }

            if let referenceTokenItem,
               let tangemPayAccount = userWalletModel.accountModelsManager.tangemPayAccountModel?.state?.tangemPayAccount,
               referenceTokenItem.token == tangemPayAccount.paymentTokenItem.token,
               referenceTokenItem.blockchain == tangemPayAccount.paymentTokenItem.blockchain,
               let depositAddress = tangemPayAccount.depositAddress {
                results.append(
                    SendDestinationSuggestedWallet(
                        name: userWalletModel.name,
                        address: depositAddress,
                        account: SendDestinationSuggestedWallet.Account(
                            icon: .init(backgroundColor: .clear, nameMode: .imageType(Assets.Visa.accountAvatar)),
                            name: Localization.tangempayPaymentAccount
                        ),
                        accountModelAnalyticsProvider: nil
                    )
                )
            }

            return results
        }

        return wallets
    }
}
