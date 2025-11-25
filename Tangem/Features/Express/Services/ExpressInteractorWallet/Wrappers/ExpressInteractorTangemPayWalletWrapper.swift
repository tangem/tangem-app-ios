//
//  ExpressInteractorTangemPayWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress

typealias ExpressInteractorTangemPayWallet = ExpressInteractorSourceWallet

struct ExpressInteractorTangemPayWalletWrapper: ExpressInteractorTangemPayWallet {
    let id: WalletModelId
    let tokenHeader: ExpressInteractorTokenHeader? = nil
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem

    let isCustom: Bool = false
    let isMainToken: Bool = false
    let defaultAddressString: String
    let availableBalanceProvider: any TokenBalanceProvider

    let sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? = .none
    let amountToCreateAccount: Decimal = .zero
    let allowanceService: (any AllowanceService)? = nil
    let withdrawalNotificationProvider: (any WithdrawalNotificationProvider)? = nil

    private var _balanceProvider: any ExpressBalanceProvider
    private var _feeProvider: any ExpressFeeProvider

    var transactionValidator: any TransactionValidator {
        // Add implementation
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        defaultAddressString: String,
        availableBalanceProvider: TokenBalanceProvider,
    ) {
        id = .init(tokenItem: tokenItem)

        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.defaultAddressString = defaultAddressString
        self.availableBalanceProvider = availableBalanceProvider

        _balanceProvider = TangemPayExpressBalanceProvider(
            availableBalanceProvider: availableBalanceProvider,
        )

        _feeProvider = TangemPayWithdrawExpressFeeProvider()
    }
}

extension ExpressInteractorTangemPayWalletWrapper {
    func cexTransactionProcessor() throws -> any ExpressCEXTransactionProcessor {
        TangemPayExpressCEXTransactionProcessor()
    }

    func dexTransactionProcessor() throws -> any ExpressDEXTransactionProcessor {
        throw ExpressTransactionProcessorFactory.Error.dexNotSupported(blockchain: "Visa")
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        let provider = ExternalLinkProviderFactory().makeProvider(for: tokenItem.blockchain)
        return provider.url(transaction: hash)
    }
}

// MARK: - ExpressSourceWallet, ExpressDestinationWallet

extension ExpressInteractorTangemPayWalletWrapper {
    var feeProvider: ExpressFeeProvider { _feeProvider }

    var balanceProvider: BalanceProvider { _balanceProvider }

    var supportedProviders: [ExpressProviderType] { [.cex] }
}
