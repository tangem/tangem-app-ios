//
//  TokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemLocalization
import TangemPay
import TangemExpress

protocol TokenSelectorWalletsProvider {
    var wallets: [TokenSelectorWallet] { get }
}

// MARK: - Implementations

extension TokenSelectorWalletsProvider where Self == CommonTokenSelectorWalletsProvider {
    static func common() -> Self { .init() }
    static func standardAccountsOnly() -> Self { .init(accountModelFilter: \.isStandard) }
}

// MARK: - Wallet

struct TokenSelectorWallet {
    let wallet: UserWalletInfo
    let accounts: AccountType
}

extension TokenSelectorWallet {
    enum AccountType {
        case single(TokenSelectorAccount)
        case multiple([TokenSelectorAccount])
    }
}

// MARK: - Nested Account

struct TokenSelectorAccount {
    let account: any BaseAccountModel
    let itemsProvider: TokenSelectorAccountModelItemsProvider
    let rateProvider: (any AccountRateProvider)?
}

// MARK: - Account's items

struct TokenSelectorItem: Hashable, Identifiable {
    enum Kind {
        case crypto(any WalletModel, any CryptoAccountModel)
        case tangemPay(TangemPayAccount, String, any TangemPayAccountModel)

        var walletModel: (any WalletModel)? {
            switch self {
            case .crypto(let walletModel, _):
                walletModel
            case .tangemPay:
                nil
            }
        }

        var account: any BaseAccountModel {
            switch self {
            case .crypto(_, let account):
                account
            case .tangemPay(_, _, let account):
                account
            }
        }
    }

    let userWalletInfo: UserWalletInfo
    let kind: Kind

    var id: String {
        WalletModelId(tokenItem: tokenItem).id
    }

    var tokenItem: TokenItem {
        switch kind {
        case .crypto(let walletModel, _):
            walletModel.tokenItem
        case .tangemPay(let tangemPayAccount, _, _):
            tangemPayAccount.paymentTokenItem
        }
    }

    var cryptoBalanceProvider: TokenBalanceProvider {
        switch kind {
        case .crypto(let walletModel, _):
            walletModel.totalTokenBalanceProvider
        case .tangemPay(let tangemPayAccount, _, _):
            tangemPayAccount.balancesProvider.totalTokenBalanceProvider
        }
    }

    var fiatBalanceProvider: TokenBalanceProvider {
        switch kind {
        case .crypto(let walletModel, _):
            walletModel.fiatTotalTokenBalanceProvider
        case .tangemPay(let tangemPayAccount, _, _):
            tangemPayAccount.balancesProvider.fiatAvailableBalanceProvider
        }
    }

    func isMatching(searchText: String) -> Bool {
        let matchingName = tokenItem.name.lowercased().contains(searchText.lowercased())
        let matchingSymbol = tokenItem.currencySymbol.lowercased().contains(searchText.lowercased())

        return matchingName || matchingSymbol
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userWalletInfo.id)
        hasher.combine(kind.account.id)
        hasher.combine(id)
    }

    static func == (lhs: TokenSelectorItem, rhs: TokenSelectorItem) -> Bool {
        lhs.userWalletInfo.id == rhs.userWalletInfo.id
            && lhs.kind.account.id == rhs.kind.account.id
            && lhs.id == rhs.id
    }
}

extension TokenSelectorItem {
    enum AvailabilityType {
        case available
        case unavailable(reason: TokenSelectorItemViewModel.DisabledReason)
    }
}

extension TokenSelectorItem {
    func makeSendSwapableTokenFactory(expressOperationType: ExpressOperationType) -> SendSwapableTokenFactory {
        switch kind {
        case .crypto(let walletModel, _):
            CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                operationType: expressOperationType
            )

        case .tangemPay(let tangemPayAccount, let depositAddress, let account):
            TangemPaySwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                account: account,
                tokenItem: TangemPayUtilities.usdcTokenItem,
                feeTokenItem: TangemPayUtilities.usdcTokenItem,
                defaultAddressString: depositAddress,
                availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
                fiatAvailableBalanceProvider: tangemPayAccount.balancesProvider.fiatAvailableBalanceProvider,
                transactionDispatcher: tangemPayAccount.transactionDispatcher,
                transactionValidator: TangemPaySendTransactionValidator(
                    availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
                ),
                operationType: expressOperationType
            )
        }
    }
}
