//
//  TransactionDetailsContext.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import TangemUI

struct TransactionDetailsContext {
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private let isAccountsMode: Bool
    weak var routable: (any TransactionDetailsRoutable)?

    let tokenIconInfo: TokenIconInfo

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        isAccountsMode: Bool,
        routable: TransactionDetailsRoutable
    ) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.isAccountsMode = isAccountsMode
        self.routable = routable
        tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    var openURL: (URL) -> Void {
        { [weak routable] url in
            routable?.openTransactionDetailsURL(url)
        }
    }

    var share: (String) -> Void {
        { [weak routable] text in
            routable?.shareFromTransactionDetails(text)
        }
    }

    #if INTERNAL || DEBUG
    var openDebug: (TransactionDetailsDebugInfo) -> Void {
        { [weak routable] info in
            routable?.openTransactionDetailsDebug(info)
        }
    }
    #endif

    var onClose: () -> Void {
        { [weak routable] in
            routable?.closeTransactionDetails()
        }
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

    /// A "go to token" action for an Express refund token. Prefers the exact token in the account that actually
    /// received the refund (resolved via `refundAddress`); otherwise opens any held match, adding the token to
    /// this account first when it isn't imported yet.
    func refundTokenNavigation(for tokenItem: TokenItem, refundAddress: String?) -> () -> Void {
        { [weak routable, walletModel = walletModel, userWalletId = userWalletInfo.id] in
            Task { @MainActor in
                if let address = refundAddress?.nilIfEmpty,
                   let received = try? WalletModelFinder.findWalletModel(
                       address: address,
                       networkId: tokenItem.blockchain.networkId,
                       isTestnet: tokenItem.blockchain.isTestnet,
                       shallowMatchingTokenItem: tokenItem
                   ) {
                    routable?.openTokenFromTransactionDetails(walletModel: received.walletModel, userWalletModel: received.userWalletModel)
                    return
                }

                if (try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, shallowMatchingTokenItem: tokenItem)) == nil {
                    _ = try? await walletModel.account?.userTokensManager.add(tokenItem)
                }

                guard let result = try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, shallowMatchingTokenItem: tokenItem) else {
                    return
                }

                routable?.openTokenFromTransactionDetails(walletModel: result.walletModel, userWalletModel: result.userWalletModel)
            }
        }
    }
}
