//
//  SendSwapStubs.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
@testable import TangemExpress
@testable import Tangem

final class ExpressAPIProviderStub: ExpressAPIProvider {
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
            externalTxURL: nil,
            payInAddress: ""
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
            toAmount: nil,
            countryCode: "",
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
            toAmount: nil,
            countryCode: "",
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

final class SendAnalyticsLoggerStub: SendAnalyticsLogger {
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
    func logSendSwapAvailable(token: String) {}
    func logSendSwapAvailableClicked(token: String) {}

    // MARK: - SendDestinationAnalyticsLogger

    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource) {}
    func logQRScannerOpened() {}
    func logDestinationStepOpened() {}
    func logAddressBookWidgetShown() {}
    func logAddressBookContactSelected(_ contact: AddressBookContact) {}
    func logAddressBookAddressSubstituted(_ contact: AddressBookContact) {}
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
    func logSendSwapFilterProviderTapped(type: Analytics.ParameterValue) {}

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
