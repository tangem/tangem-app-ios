//
//  TransactionDetailsContext.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAccounts
import TangemAssets
import TangemUI

struct TransactionDetailsContext {
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository

    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private let isAccountsMode: Bool

    let tokenIconInfo: TokenIconInfo

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        isAccountsMode: Bool
    ) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.isAccountsMode = isAccountsMode
        tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    var blockchain: Blockchain {
        walletModel.tokenItem.blockchain
    }

    var networkIconAsset: ImageType {
        NetworkImageProvider().provide(by: walletModel.tokenItem.blockchain, filled: true)
    }

    func tokenIconInfo(forContract contract: String) -> TokenIconInfo? {
        let blockchain = walletModel.tokenItem.blockchain
        let comparator = AddressComparator()

        let walletModels = walletModel.account?.walletModelsManager.walletModels ?? []

        let matching: (any WalletModel)? = walletModels.first { model in
            guard let contractAddress: String = model.tokenItem.contractAddress else {
                return false
            }

            return model.tokenItem.blockchainNetwork == walletModel.tokenItem.blockchainNetwork
                && comparator.addressesMatch(contractAddress, contract, blockchain: blockchain)
        }

        guard let matching else {
            return knownTokenIconInfo(forContract: contract)
        }

        return TokenIconInfoBuilder().build(from: matching.tokenItem, isCustom: matching.isCustom)
    }

    /// A token outside the account, e.g. an approve of a token the user doesn't hold, is looked up among all the
    /// tokens known on the network. A cache miss fires a background load, and the sheet re-renders once it lands.
    private func knownTokenIconInfo(forContract contract: String) -> TokenIconInfo? {
        auxDataRepository
            .cryptoCurrency(forContract: contract, blockchain: walletModel.tokenItem.blockchain)
            .map { TokenIconInfoBuilder().build(from: $0, isCustom: false) }
    }

    var tokenSymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    var tokenCurrencyId: String? {
        walletModel.tokenItem.currencyId
    }

    var receiverName: String {
        guard isAccountsMode, let account = walletModel.account else {
            return userWalletInfo.name
        }

        return account.name
    }

    var receiverAccountIcon: AccountIconView.ViewData? {
        guard isAccountsMode, let account = walletModel.account else {
            return nil
        }

        return AccountModelUtils.UI.iconViewData(accountModel: account)
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        walletModel.exploreTransactionURL(for: hash)
    }
}
