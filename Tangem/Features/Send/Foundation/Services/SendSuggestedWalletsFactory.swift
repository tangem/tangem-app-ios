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
            ignoredAddresses: walletModel.addresses.toSet(),
            referenceTokenItem: walletModel.tokenItem
        )
    }

    /// - Parameter referenceTokenItem: When non-nil, used to match TangemPay deposit accounts
    ///   so that a Visa deposit address is included in the suggested wallets.
    func makeSuggestedWallets(
        targetNetworkId: String,
        ignoredAddresses: Set<String>,
        referenceTokenItem: TokenItem
    ) -> [SendDestinationSuggestedWallet] {
        let shouldShowAccounts = cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple

        let wallets = userWalletRepository.models.flatMap { userWalletModel in
            let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

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

            if let tangemPayAccount = userWalletModel.accountModelsManager.tangemPayAccountModel?.state?.tangemPayAccount,
               referenceTokenItem.token == tangemPayAccount.paymentTokenItem.token,
               referenceTokenItem.blockchain == tangemPayAccount.paymentTokenItem.blockchain,
               let depositAddress = tangemPayAccount.depositAddress {
                results.append(
                    SendDestinationSuggestedWallet(
                        name: userWalletModel.name,
                        address: depositAddress,
                        account: SendDestinationSuggestedWallet.Account(
                            icon: .plain(image: Assets.Visa.accountAvatar),
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
