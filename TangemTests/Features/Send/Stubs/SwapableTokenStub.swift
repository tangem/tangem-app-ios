//
//  SwapableTokenStub.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
@testable import Tangem

final class SwapableTokenStub: SendSwapableToken {
    private let inner: SendSourceTokenStub
    private let sendingRestriction: SendingRestrictions?

    init(blockchain: Blockchain, sendingRestriction: SendingRestrictions? = nil) {
        inner = SendSourceTokenStub(blockchain: blockchain)
        self.sendingRestriction = sendingRestriction
    }

    init(tokenItem: TokenItem, sendingRestriction: SendingRestrictions? = nil) {
        inner = SendSourceTokenStub(tokenItem: tokenItem)
        self.sendingRestriction = sendingRestriction
    }

    var sendingRestrictionsProvider: any SendingRestrictionsProvider {
        SendingRestrictionsProviderStub(sendingRestrictions: sendingRestriction)
    }

    // MARK: - SendSourceToken proxy

    var tokenItem: TokenItem { inner.tokenItem }
    var isCustom: Bool { inner.isCustom }
    var fiatItem: FiatItem { inner.fiatItem }
    var userWalletInfo: UserWalletInfo { inner.userWalletInfo }
    var id: WalletModelId { inner.id }
    var header: TokenHeader { inner.header }
    var feeTokenItem: TokenItem { inner.feeTokenItem }
    var defaultAddressString: String { inner.defaultAddressString }
    var availableBalanceProvider: TokenBalanceProvider { inner.availableBalanceProvider }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { inner.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { inner.allowanceService }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { inner.withdrawalNotificationProvider }
    var scaledUIAmountMultiplierResolver: ScaledUIAmountMultiplierResolver? { inner.scaledUIAmountMultiplierResolver }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { inner.emailDataCollectorBuilder }
    var transactionHistoryEnricher: TransactionHistoryExpressDataEnriching? { get async { await inner.transactionHistoryEnricher } }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { inner.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { inner.accountModelAnalyticsProvider }
    var tangemIconProvider: any TangemIconProvider { inner.tangemIconProvider }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { inner.confirmTransactionPolicy }
    var isTangemPayAccount: Bool { inner.isTangemPayAccount }

    // MARK: - Swap members

    var isExemptFee: Bool { false }
    var swapAvailabilityProvider: any SwapAvailabilityProvider { SwapAvailabilityProviderStub(isSwapAvailable: true) }
    var supportedProvidersFilter: SupportedProvidersFilter { .byDifferentAddressExchangeSupport }
    var sendYieldModuleHelper: SendYieldModuleHelper? { nil }
    var operationType: ExpressOperationType { .swapAndSend }
    /// When the stub plays the destination, the pair-update task queries its restrictions from a
    /// detached task — a `fatalError` here crashes the whole run intermittently.
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { NoReceivingRestrictionsStub() }

    // MARK: - Unused in tests

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManager: any TokenFeeProvidersManager { fatalError("Unused in tests") }
    var transactionValidator: any SendTransactionValidator { fatalError("Unused in tests") }
    var transactionCreator: any SendTransactionCreator { fatalError("Unused in tests") }
    var balanceProvider: any BalanceProvider { fatalError("Unused in tests") }
    var analyticsLogger: any AnalyticsLogger { fatalError("Unused in tests") }
    var providerTransactionValidator: any ExpressProviderTransactionValidator { fatalError("Unused in tests") }
}

struct SwapAvailabilityProviderStub: SwapAvailabilityProvider {
    let isSwapAvailable: Bool
}

private struct NoReceivingRestrictionsStub: ReceivingRestrictionsProvider {
    func restriction(expectAmount: Decimal) -> ReceivedRestriction? { nil }
}

private struct SendingRestrictionsProviderStub: SendingRestrictionsProvider {
    let sendingRestrictions: SendingRestrictions?
}

// MARK: - Token item helpers

extension TokenItem {
    /// A payment-account-style token, on Polygon unless said otherwise.
    static func accountToken(
        symbol: String,
        contract: String,
        decimalCount: Int = 6,
        blockchain: Blockchain = .polygon(testnet: false)
    ) -> TokenItem {
        .token(
            Token(
                name: symbol,
                symbol: symbol,
                contractAddress: contract,
                decimalCount: decimalCount,
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(blockchain, derivationPath: nil)
        )
    }

    static func tronToken(symbol: String, contract: String) -> TokenItem {
        .token(
            Token(
                name: symbol,
                symbol: symbol,
                contractAddress: contract,
                decimalCount: 6,
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(.tron(testnet: false), derivationPath: nil)
        )
    }
}
