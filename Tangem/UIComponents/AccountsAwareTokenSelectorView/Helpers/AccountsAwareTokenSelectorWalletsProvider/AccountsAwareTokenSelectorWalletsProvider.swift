//
//  AccountsAwareTokenSelectorWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemAccounts
import TangemExpress
import TangemPay

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
    let accountName: String
    let accountIcon: AccountModel.Icon
    let itemsProvider: AccountsAwareTokenSelectorAccountModelItemsProvider
}

// MARK: - Account's items

struct AccountsAwareTokenSelectorItem: Hashable, Identifiable {
    var id: String { walletModelId.id }

    let userWalletInfo: UserWalletInfo
    let source: Source

    var walletModelId: WalletModelId {
        switch source {
        case .crypto(_, let walletModel):
            walletModel.id
        case .tangemPay:
            WalletModelId(tokenItem: TangemPayUtilities.usdcTokenItem)
        }
    }

    var tokenItem: TokenItem {
        switch source {
        case .crypto(_, let walletModel):
            walletModel.tokenItem
        case .tangemPay:
            TangemPayUtilities.usdcTokenItem
        }
    }

    var isCustom: Bool {
        switch source {
        case .crypto(_, let walletModel):
            walletModel.isCustom
        case .tangemPay:
            false
        }
    }

    var cryptoBalanceProvider: TokenBalanceProvider {
        switch source {
        case .crypto(_, let walletModel):
            walletModel.totalTokenBalanceProvider
        case .tangemPay(let account):
            account.balancesProvider.totalTokenBalanceProvider
        }
    }

    var fiatBalanceProvider: TokenBalanceProvider {
        switch source {
        case .crypto(_, let walletModel):
            walletModel.fiatTotalTokenBalanceProvider
        case .tangemPay(let account):
            account.balancesProvider.fiatTotalTokenBalanceProvider
        }
    }

    func isMatching(searchText: String) -> Bool {
        let name = tokenItem.name.lowercased()
        let symbol = tokenItem.currencySymbol.lowercased()
        let search = searchText.lowercased()
        return name.contains(search) || symbol.contains(search)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userWalletInfo.id)
        switch source {
        case .crypto(let account, _):
            hasher.combine(account.id)
        case .tangemPay(let account):
            hasher.combine(account.customerId)
        }
        hasher.combine(walletModelId)
    }

    static func == (lhs: AccountsAwareTokenSelectorItem, rhs: AccountsAwareTokenSelectorItem) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension AccountsAwareTokenSelectorItem {
    enum Source {
        case crypto(account: any CryptoAccountModel, walletModel: any WalletModel)
        case tangemPay(TangemPayAccount)
    }

    enum AvailabilityType {
        case available
        case unavailable(reason: AccountsAwareTokenSelectorItemViewModel.DisabledReason)
    }

    func makeExpressInteractorWallet(
        expressOperationType: ExpressOperationType = .swap,
        isNewlyAddedFromMarkets: Bool = false
    ) -> any ExpressInteractorSourceWallet {
        switch source {
        case .crypto(_, let walletModel):
            ExpressInteractorWalletModelWrapper(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                expressOperationType: expressOperationType,
                isNewlyAddedFromMarkets: isNewlyAddedFromMarkets
            )

        case .tangemPay(let account):
            ExpressInteractorTangemPayWalletWrapper(
                userWalletId: userWalletInfo.id,
                tokenItem: TangemPayUtilities.usdcTokenItem,
                feeTokenItem: TangemPayUtilities.usdcTokenItem,
                defaultAddressString: account.depositAddress ?? "",
                availableBalanceProvider: account.balancesProvider.availableBalanceProvider,
                cexTransactionDispatcher: account.expressCEXTransactionDispatcher,
                transactionValidator: TangemPayExpressTransactionValidator(
                    availableBalanceProvider: account.balancesProvider.availableBalanceProvider
                )
            )
        }
    }
}
