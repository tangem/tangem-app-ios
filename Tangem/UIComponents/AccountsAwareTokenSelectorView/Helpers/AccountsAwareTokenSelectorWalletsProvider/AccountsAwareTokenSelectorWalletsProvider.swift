//
//  AccountsAwareTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemLocalization
import TangemPay
import TangemExpress

protocol AccountsAwareTokenSelectorWalletsProvider {
    var wallets: [AccountsAwareTokenSelectorWallet] { get }
}

// MARK: - Implementations

extension AccountsAwareTokenSelectorWalletsProvider where Self == CommonAccountsAwareTokenSelectorWalletsProvider {
    static func common() -> Self { .init() }
}

// MARK: - Wallet

struct AccountsAwareTokenSelectorWallet {
    let wallet: UserWalletInfo
    let accounts: AccountType
    let accountsPublisher: AnyPublisher<AccountType, Never>
}

extension AccountsAwareTokenSelectorWallet {
    enum AccountType {
        case single(AccountsAwareTokenSelectorAccount)
        case multiple([AccountsAwareTokenSelectorAccount])
    }
}

// MARK: - Nested Account

struct AccountsAwareTokenSelectorAccount {
    let account: any BaseAccountModel
    let itemsProvider: AccountsAwareTokenSelectorAccountModelItemsProvider
}

// MARK: - Account's items

struct AccountsAwareTokenSelectorItem: Hashable, Identifiable {
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

    static func == (lhs: AccountsAwareTokenSelectorItem, rhs: AccountsAwareTokenSelectorItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension AccountsAwareTokenSelectorItem {
    enum AvailabilityType {
        case available
        case unavailable(reason: AccountsAwareTokenSelectorItemViewModel.DisabledReason)
    }
}

extension AccountsAwareTokenSelectorItem {
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
                cexTransactionDispatcher: tangemPayAccount.expressCEXTransactionDispatcher,
                transactionValidator: TangemPayExpressTransactionValidator(
                    availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
                ),
                operationType: expressOperationType
            )
        }
    }
}
