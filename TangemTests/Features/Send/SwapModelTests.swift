//
//  SwapModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import Testing
import TangemTestKit
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel")
final class SwapModelTests: LeakTrackingTestSuite {
    @Test("SwapModel deallocates properly without memory leaks")
    func swapModelDeallocatesProperly() async {
        let sut = makeSUT()
        trackForMemoryLeaks(sut)

        _ = sut.sourceToken
        _ = sut.receiveToken
        _ = sut.statePublisher
    }
}

// MARK: - Helpers

private extension SwapModelTests {
    func makeSUT() -> SwapModel {
        SwapModel(
            sourceToken: nil,
            receiveToken: nil,
            expressManager: ExpressManagerStub(),
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressDestinationService: ExpressDestinationServiceStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: SwapPairUpdateHandlerStub(),
            balanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureCheckerStub(),
            shouldStartInitialLoading: false
        )
    }
}

// MARK: - Stubs

private actor ExpressManagerStub: ExpressManager {
    func getCurrentPair() -> ExpressManagerSwappingPair? { nil }
    func getAmountType() -> ExpressAmountType? { nil }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        .idle
    }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        .idle
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        .idle
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState {
        .idle
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        .idle
    }

    func requestData() async throws -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            txValue: .zero,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil
        )
    }
}

private final class SwapRepositoryStub: SwapRepository {
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {}
    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {}
    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] { [] }
    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }

    // ExpressRepository
    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}
    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] { [] }
}

private final class ExpressPendingTransactionRepositoryStub: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] { [] }
    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { .just(output: []) }
    func updateItems(_ items: [ExpressPendingTransactionRecord]) {}
    func swapTransactionDidSend(_ transaction: SentSwapTransactionData) {}
    func hideSwapTransaction(with id: String) {}
}

private final class ExpressDestinationServiceStub: ExpressDestinationService {
    func getSource(destination: TokenItem) async throws -> any SendSwapableToken {
        throw ExpressDestinationServiceError.sourceNotFound(destination: destination)
    }

    func getDestination(source: TokenItem) async throws -> any SendSwapableToken {
        throw ExpressDestinationServiceError.destinationNotFound(source: source)
    }
}

private final class ExpressAPIProviderStub: ExpressAPIProvider {
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { [] }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { [] }
    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] { [] }

    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote {
        ExpressQuote(fromAmount: .zero, expectAmount: .zero, allowanceContract: nil, quoteId: nil, txType: nil)
    }

    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            txValue: .zero,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    func exchangeStatus(transactionId: String) async throws -> ExchangeTransaction {
        fatalError("Not used in tests")
    }

    func exchangeSent(result: ExpressTransactionSentResult) async throws {}

    // Onramp
    func onrampCurrencies() async throws -> [OnrampFiatCurrency] { [] }
    func onrampCountries() async throws -> [OnrampCountry] { [] }

    func onrampCountryByIP() async throws -> OnrampCountry {
        let currency = OnrampFiatCurrency(identity: OnrampIdentity(name: "", code: "", image: nil), precision: 0)
        return OnrampCountry(identity: currency.identity, currency: currency, onrampAvailable: false)
    }

    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod] { [] }
    func onrampPairs(from: OnrampFiatCurrency, to: [ExpressWalletCurrency], country: OnrampCountry) async throws -> [OnrampPair] { [] }

    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote {
        OnrampQuote(expectedAmount: .zero, nativePaymentAvailable: false, quoteId: nil)
    }

    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData {
        OnrampRedirectData(
            txId: "",
            widgetURL: URL(string: "https://stub")!,
            redirectURL: URL(string: "https://stub")!,
            fromAmount: .zero,
            fromCurrencyCode: "",
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    func onrampNativePaymentData(item: OnrampNativePaymentRequestItem) async throws -> OnrampDataResult {
        .widget(OnrampRedirectData(
            txId: "",
            widgetURL: URL(string: "https://stub")!,
            redirectURL: URL(string: "https://stub")!,
            fromAmount: .zero,
            fromCurrencyCode: "",
            externalTxId: nil,
            externalTxURL: nil
        ))
    }

    func onrampStatus(transactionId: String) async throws -> OnrampTransaction {
        fatalError("Not used in tests")
    }

    /// History
    func exchangeHistory(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage {
        ExchangeHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func exchangeHistoryDelta(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage {
        ExchangeHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func onrampHistory(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage {
        OnrampHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func onrampHistoryDelta(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage {
        OnrampHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }
}

private final class SendAnalyticsLoggerStub: SendAnalyticsLogger {
    // MARK: - SendAnalyticsLogger

    func setup(sendDestinationInput: any SendDestinationInput) {}
    func setup(sendFeeInput: any SendFeeInput) {}
    func setup(sendSourceTokenInput: any SendSourceTokenInput) {}
    func setup(sendReceiveTokenInput: any SendReceiveTokenInput) {}
    func setup(sendSwapProvidersInput: any SendSwapProvidersInput) {}

    // MARK: - SendManagementModelAnalyticsLogger

    func logTransactionRejected(error: SendTxError) {}
    func logTransactionSent(amount: SendAmount?, additionalField: SendDestinationAdditionalField?, fee: FeeOption, signerType: String, currentProviderHost: String, tokenFee: TokenFee?) {}

    // MARK: - SendBaseViewAnalyticsLogger

    func logSendBaseViewOpened() {}
    func logRequestSupport() {}
    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {}

    // MARK: - SendAmountAnalyticsLogger

    func logTapMaxAmount() {}
    func logTapConvertToAnotherToken() {}
    func logAmountStepOpened() {}
    func logAmountStepReopened() {}
    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue) {}
    func logSwapErrorMinAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {}
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {}

    // MARK: - SendReceiveTokensListAnalyticsLogger

    func logSearchClicked() {}
    func logTokenSearched(coin: CoinModel, searchText: String?) {}
    func logTokenChosen(token: TokenItem) {}
    func logSendSwapCantSwapThisToken(token: String) {}

    // MARK: - SendDestinationAnalyticsLogger

    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource) {}
    func logQRScannerOpened() {}
    func logDestinationStepOpened() {}
    func logDestinationStepReopened() {}
    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?) {}

    // MARK: - SendFeeAnalyticsLogger

    func logFeeSelected(tokenFee: TokenFee) {}
    func logFeeSelected(_ feeOption: FeeOption) {}
    func logSendNoticeTransactionDelaysArePossible() {}
    func logFeeStepOpened() {}
    func logFeeStepReopened() {}
    func logFeeSummaryOpened() {}
    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {}

    // MARK: - FeeSelectorAnalytics

    func logCustomFeeClicked() {}

    // MARK: - SendSwapProvidersAnalyticsLogger

    func logSendSwapProvidersChosen(provider: ExpressProvider) {}

    // MARK: - SendSummaryAnalyticsLogger

    func logUserDidTapOnValidator() {}
    func logUserDidTapOnProvider() {}
    func logSummaryStepOpened() {}
    func logTapAmountFraction(_ fraction: SwapAmountFraction) {}

    // MARK: - SendFinishAnalyticsLogger

    func logFinishStepOpened() {}
    func logShareButton() {}
    func logExploreButton() {}

    // MARK: - SendApproveAnalyticsLogger

    func logPermissionScreenOpened(isRevoke: Bool) {}
    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy) {}
    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {}

    // MARK: - SwapManagementModelAnalyticsLogger

    func logSwapButtonSwap() {}
    func logSwapButtonTransfer() {}
    func logSwapTransferModeSwitched() {}
    func logSwapTransactionSent(result: TransactionDispatcherResult) {}
    func logSwapPreselectedTokenChanged(direction: Analytics.ParameterValue, preselectedSymbol: String, selectedSymbol: String) {}
}

private final class SwapPairUpdateHandlerStub: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class SwapBalanceRestrictionFeatureCheckerStub: SwapBalanceRestrictionFeatureChecker {
    func hasSwapTotalBalanceRestriction(for token: SendSourceToken) async throws -> Bool { false }
}
