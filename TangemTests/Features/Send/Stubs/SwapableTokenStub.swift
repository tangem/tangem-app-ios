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
    private let receivingRestriction: ReceivedRestriction?
    private let validator: SendTransactionValidator?
    private let receiveDestination: SendReceiveTokenDestination?
    private let balanceProviders: BalanceProviders?
    private let feeProvidersManager: (any TokenFeeProvidersManager)?
    private let defaultAddress: String?
    private let injectedReceivingRestrictionsProvider: (any ReceivingRestrictionsProvider)?

    let presentation: SendReceiveTokenPresentation?

    init(
        blockchain: Blockchain,
        sendingRestriction: SendingRestrictions? = nil,
        receivingRestriction: ReceivedRestriction? = nil,
        transactionValidator: SendTransactionValidator? = nil,
        destination: SendReceiveTokenDestination? = nil,
        receivingRestrictionsProvider: (any ReceivingRestrictionsProvider)? = nil
    ) {
        inner = SendSourceTokenStub(blockchain: blockchain)
        self.sendingRestriction = sendingRestriction
        self.receivingRestriction = receivingRestriction
        validator = transactionValidator
        receiveDestination = destination
        balanceProviders = nil
        feeProvidersManager = nil
        defaultAddress = nil
        presentation = nil
        injectedReceivingRestrictionsProvider = receivingRestrictionsProvider
    }

    init(
        tokenItem: TokenItem,
        sendingRestriction: SendingRestrictions? = nil,
        receivingRestriction: ReceivedRestriction? = nil,
        transactionValidator: SendTransactionValidator? = nil,
        destination: SendReceiveTokenDestination? = nil,
        balanceProviders: BalanceProviders? = nil,
        presentation: SendReceiveTokenPresentation? = nil,
        tokenFeeProvidersManager: (any TokenFeeProvidersManager)? = nil,
        defaultAddress: String? = nil,
        receivingRestrictionsProvider: (any ReceivingRestrictionsProvider)? = nil
    ) {
        inner = SendSourceTokenStub(tokenItem: tokenItem)
        self.sendingRestriction = sendingRestriction
        self.receivingRestriction = receivingRestriction
        validator = transactionValidator
        receiveDestination = destination
        self.balanceProviders = balanceProviders
        self.presentation = presentation
        feeProvidersManager = tokenFeeProvidersManager
        self.defaultAddress = defaultAddress
        injectedReceivingRestrictionsProvider = receivingRestrictionsProvider
    }

    struct BalanceProviders {
        let available: TokenBalanceProvider
        let fiatAvailable: TokenBalanceProvider
    }

    var sendingRestrictionsProvider: any SendingRestrictionsProvider {
        SendingRestrictionsProviderStub(sendingRestrictions: sendingRestriction)
    }

    var destination: SendReceiveTokenDestination? {
        receiveDestination ?? SendReceiveTokenDestination(destination: .plain(defaultAddressString), destinationTag: nil)
    }

    // MARK: - SendSourceToken proxy

    var tokenItem: TokenItem { inner.tokenItem }
    var isCustom: Bool { inner.isCustom }
    var fiatItem: FiatItem { inner.fiatItem }
    var userWalletInfo: UserWalletInfo { inner.userWalletInfo }
    var id: WalletModelId { inner.id }
    var header: TokenHeader { inner.header }
    var feeTokenItem: TokenItem { inner.feeTokenItem }
    var defaultAddressString: String { defaultAddress ?? inner.defaultAddressString }
    var availableBalanceProvider: TokenBalanceProvider { balanceProviders?.available ?? inner.availableBalanceProvider }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { balanceProviders?.fiatAvailable ?? inner.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { inner.allowanceService }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { inner.withdrawalNotificationProvider }
    var scaledUIAmountMultiplierResolver: ScaledUIAmountMultiplierResolver? { inner.scaledUIAmountMultiplierResolver }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { inner.emailDataCollectorBuilder }
    var transactionHistoryEnricher: TransactionHistoryExpressDataEnriching? { get async { await inner.transactionHistoryEnricher } }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { inner.transactionDispatcherProvider }
    var transactionSummaryDescriptionBuilderProvider: any TransactionSummaryDescriptionBuilderProvider { inner.transactionSummaryDescriptionBuilderProvider }
    var blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper { inner.blockchainSDKNotificationMapper }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { inner.accountModelAnalyticsProvider }
    var isTangemPayAccount: Bool { inner.isTangemPayAccount }
    var jointAccountPolicy: JointAccountPolicy? { inner.jointAccountPolicy }

    // MARK: - Swap members

    var isExemptFee: Bool { false }
    var swapAvailabilityProvider: any SwapAvailabilityProvider { SwapAvailabilityProviderStub(isSwapAvailable: true) }
    var supportedProvidersFilter: SupportedProvidersFilter { .byDifferentAddressExchangeSupport }
    var sendYieldModuleHelper: SendYieldModuleHelper? { nil }
    var operationType: ExpressOperationType { .swapAndSend }
    /// When the stub plays the destination, the pair-update task queries its restrictions from a
    /// detached task — a `fatalError` here crashes the whole run intermittently.
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider {
        injectedReceivingRestrictionsProvider ?? ReceivingRestrictionsProviderStub(result: receivingRestriction)
    }

    var transactionValidator: any SendTransactionValidator {
        guard let validator else {
            fatalError("Unused in tests")
        }

        return validator
    }

    // MARK: - Unused in tests

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManager: any TokenFeeProvidersManager {
        guard let feeProvidersManager else {
            fatalError("Unused in tests")
        }

        return feeProvidersManager
    }

    var transactionCreator: any SendTransactionCreator { fatalError("Unused in tests") }
    var balanceProvider: any BalanceProvider { fatalError("Unused in tests") }
    var analyticsLogger: any AnalyticsLogger { fatalError("Unused in tests") }
    var providerTransactionValidator: any ExpressProviderTransactionValidator { fatalError("Unused in tests") }
}

struct SwapAvailabilityProviderStub: SwapAvailabilityProvider {
    let isSwapAvailable: Bool
}

private struct ReceivingRestrictionsProviderStub: ReceivingRestrictionsProvider {
    let result: ReceivedRestriction?

    var isRestrictionKnown: Bool { true }
    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? { result }
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
