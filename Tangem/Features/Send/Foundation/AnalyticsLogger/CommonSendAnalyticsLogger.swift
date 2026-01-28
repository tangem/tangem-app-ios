//
//  CommonSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

class CommonSendAnalyticsLogger {
    private weak var sendDestinationInput: SendDestinationInput?
    private weak var sendFeeInput: SendFeeInput?
    private weak var sendSourceTokenInput: SendSourceTokenInput?
    private weak var sendReceiveTokenInput: SendReceiveTokenInput?
    private weak var sendSwapProvidersInput: SendSwapProvidersInput?

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private let sendType: SendType

    private var destinationAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    private var sourceFlow: Analytics.ParameterValue {
        switch sendReceiveTokenInput?.receiveToken {
        case .same, .none: .send
        case .swap: .sendAndSwap
        }
    }

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        sendType: SendType
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.sendType = sendType
    }

    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?) {
        destinationAnalyticsProvider = analyticsProvider
    }

    private func buildAccountAnalyticsParameters() -> [Analytics.ParameterKey: String] {
        guard FeatureProvider.isAvailable(.accounts) else {
            return [:]
        }

        var result: [Analytics.ParameterKey: String] = [:]

        if let sourceAccount = sendSourceTokenInput?.sourceToken.accountModelAnalyticsProvider {
            let builder = PairedAccountAnalyticsBuilder(role: .source)
            result.merge(sourceAccount.analyticsParameters(with: builder)) { $1 }
        }

        if let destinationAnalyticsProvider {
            let builder = PairedAccountAnalyticsBuilder(role: .destination)
            result.merge(destinationAnalyticsProvider.analyticsParameters(with: builder)) { $1 }
        }

        return result
    }
}

// MARK: - SendDestinationAnalyticsLogger

extension CommonSendAnalyticsLogger: SendDestinationAnalyticsLogger {
    func logDestinationStepOpened() {
        Analytics.log(
            .sendAddressScreenOpened,
            params: [.source: sourceFlow],
            analyticsSystems: .all
        )
    }

    func logDestinationStepReopened() {
        Analytics.log(.sendScreenReopened, params: [.method: .address])
    }

    func logQRScannerOpened() {
        Analytics.log(.sendButtonQRCode)
    }

    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource) {
        guard let parameterValue = addressSource.parameterValue else {
            return
        }

        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSendAddressEntered
        default: .sendAddressEntered
        }

        Analytics.log(
            event,
            params: [
                .method: parameterValue,
                .validation: isAddressValid ? .success : .fail,
                .source: sourceFlow,
            ]
        )
    }
}

// MARK: - SendAnalyticsLogger, FeeSelectorAnalytics

extension CommonSendAnalyticsLogger: SendFeeAnalyticsLogger, FeeSelectorAnalytics {
    func logCustomFeeClicked() {
        Analytics.log(
            event: .sendCustomFeeClicked,
            params: [.token: tokenItem.currencySymbol, .blockchain: tokenItem.blockchain.displayName]
        )
    }

    func logFeeSummaryOpened() {
        Analytics.log(
            event: .sendFeeSummaryScreenOpened,
            params: [
                .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
                .blockchain: tokenItem.blockchain.displayName,
            ]
        )
    }

    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {
        let availableFeeParam = availableTokenFees.map { SendAnalyticsHelper.makeAnalyticsTokenName(from: $0.tokenItem) }.joined(separator: ", ")

        Analytics.log(
            event: .sendFeeTokenScreenOpened,
            params: [.availableFee: availableFeeParam, .blockchain: tokenItem.blockchain.displayName]
        )
    }

    func logFeeStepOpened() {
        switch tokenItem.token?.metadata.kind {
        case .fungible, .none:
            Analytics.log(
                event: .sendFeeScreenOpened,
                params: [
                    .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
                    .blockchain: tokenItem.blockchain.displayName,
                ]
            )
        case .nonFungible:
            Analytics.log(.nftCommissionScreenOpened)
        }
    }

    func logFeeStepReopened() {
        switch tokenItem.token?.metadata.kind {
        case .nonFungible:
            Analytics.log(.nftCommissionScreenOpened)
        case .fungible, .none:
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        }
    }

    func logFeeSelected(tokenFee: TokenFee) {
        let feeTypeParam = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: tokenFee.option)
        let blockchainParam = tokenFee.tokenItem.blockchain.displayName
        let sourceParam = sourceFlow

        if case .nonFungible = tokenItem.token?.metadata.kind {
            Analytics.log(
                event: .nftFeeSelected,
                params: [.feeType: feeTypeParam.rawValue, .blockchain: blockchainParam, .source: sourceParam.rawValue]
            )
        } else {
            let feeTokenParam = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)
            let params: [Analytics.ParameterKey: String] = [
                .feeToken: feeTokenParam,
                .feeType: feeTypeParam.rawValue,
                .source: sourceParam.rawValue,
                .blockchain: blockchainParam,
            ]

            Analytics.log(event: .sendFeeSelected, params: params)
        }
    }

    func logFeeSelected(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
            return
        }

        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: feeOption)
        let event: Analytics.Event
        let source: Analytics.ParameterValue?

        switch tokenItem.token?.metadata.kind {
        case .fungible, .none:
            event = .sendFeeSelected
            source = sourceFlow
        case .nonFungible:
            event = .nftFeeSelected
            source = nil
        }

        var params: [Analytics.ParameterKey: String] = [.feeType: feeType.rawValue]
        params[.source] = source?.rawValue

        Analytics.log(event: event, params: params)
    }

    func logSendNoticeTransactionDelaysArePossible() {
        Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
            .token: feeTokenItem.currencySymbol,
        ])
    }
}

// MARK: - SendAmountAnalyticsLogger

extension CommonSendAnalyticsLogger: SendAmountAnalyticsLogger {
    func logTapMaxAmount() {
        var params: [Analytics.ParameterKey: String] = [.source: sourceFlow.rawValue]

        if let token = sendSourceTokenInput?.sourceToken {
            params[.token] = token.tokenItem.currencySymbol
            params[.blockchain] = token.tokenItem.blockchain.displayName
        }

        Analytics.log(event: .sendMaxAmountTapped, params: params)
    }

    func logTapConvertToAnotherToken() {
        var params: [Analytics.ParameterKey: String] = [:]

        if let token = sendSourceTokenInput?.sourceToken {
            params[.token] = token.tokenItem.currencySymbol
            params[.blockchain] = token.tokenItem.blockchain.displayName
        }

        Analytics.log(event: .sendButtonConvertToken, params: params)
    }

    func logAmountStepOpened() {
        Analytics.log(
            .sendAmountScreenOpened,
            params: [.source: sourceFlow],
            analyticsSystems: .all
        )
    }

    func logAmountStepReopened() {
        Analytics.log(.sendScreenReopened, params: [.source: .amount])
    }
}

// MARK: - SendSwapProvidersAnalyticsLogger

extension CommonSendAnalyticsLogger: SendSwapProvidersAnalyticsLogger {
    func logSendSwapProvidersChosen(provider: ExpressProvider) {
        Analytics.log(event: .sendProviderChosen, params: [.provider: provider.name])
    }
}

// MARK: - SendReceiveTokensListAnalyticsLogger

extension CommonSendAnalyticsLogger: SendReceiveTokensListAnalyticsLogger {
    func logSearchClicked() {
        Analytics.log(.sendTokenSearchedClicked)
    }

    func logTokenSearched(coin: CoinModel, searchText: String?) {
        Analytics.log(event: .sendTokenSearched, params: [
            .tokenChosen: Analytics.ParameterValue.affirmativeOrNegative(for: searchText != nil).rawValue,
            .token: coin.symbol,
        ])
    }

    func logTokenChosen(token: TokenItem) {
        Analytics.log(event: .sendTokenChosen, params: [
            .token: token.currencySymbol,
            .blockchain: token.blockchain.displayName,
        ])
    }

    func logSendSwapCantSwapThisToken(token: String) {
        Task {
            var analyticsParameters: [Analytics.ParameterKey: String] = [:]

            if let source = sendSourceTokenInput?.sourceToken {
                analyticsParameters[.sendToken] = source.tokenItem.currencySymbol
                analyticsParameters[.sendBlockchain] = source.tokenItem.blockchain.displayName
            }

            analyticsParameters[.receiveToken] = token

            if let provider = await sendSwapProvidersInput?.selectedExpressProvider {
                analyticsParameters[.provider] = provider.provider.name
            }

            Analytics.log(event: .sendNoticeCantSwapThisToken, params: analyticsParameters)
        }
    }
}

// MARK: - SendSummaryAnalyticsLogger

extension CommonSendAnalyticsLogger: SendSummaryAnalyticsLogger {
    func logSummaryStepOpened() {
        switch tokenItem.token?.metadata.kind {
        case .fungible, .none:
            var params: [Analytics.ParameterKey: String] = [
                .source: sourceFlow.rawValue,
                .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
                .blockchain: tokenItem.blockchain.displayName,
            ]

            if let tokenFeeTokenitem = sendFeeInput?.selectedFee?.tokenItem {
                params[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFeeTokenitem)
            }

            Analytics.log(event: .sendConfirmScreenOpened, params: params, analyticsSystems: .all)
        case .nonFungible:
            Analytics.log(
                event: .nftConfirmScreenOpened,
                params: [.blockchain: tokenItem.blockchain.displayName]
            )
        }
    }

    func logUserDidTapOnValidator() {}
    func logUserDidTapOnProvider() {
        Analytics.log(.sendProviderClicked)
    }
}

// MARK: - SendFinishAnalyticsLogger

extension CommonSendAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        switch sendReceiveTokenInput?.receiveToken {
        // Old send, simple send
        case .none, .same:
            logSendFinishScreenOpened(destinationDidResolved: sendDestinationInput?.destination?.value.isResolved ?? false)
        case .swap:
            logSendWithSwapFinishScreenOpened()
        }
    }

    func logShareButton() {
        Analytics.log(.sendButtonShare)
    }

    func logExploreButton() {
        Analytics.log(.sendButtonExplore)
    }

    private func logSendFinishScreenOpened(destinationDidResolved: Bool) {
        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSentScreenOpened
        default: .sendTransactionSentScreenOpened
        }

        let feeTypeAnalyticsParameter = feeAnalyticsParameterBuilder.analyticsParameter(
            selectedFee: sendFeeInput?.selectedFee?.option
        )

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeTypeAnalyticsParameter.rawValue,
            .ensAddress: Analytics.ParameterValue.boolState(for: destinationDidResolved).rawValue,
        ]

        if let tokenFee = sendFeeInput?.selectedFee {
            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)
        }

        if let parameters = sendFeeInput?.selectedFee?.value.value?.parameters as? EthereumFeeParameters,
           let nonce = parameters.nonce {
            analyticsParameters[.nonce] = String(nonce)
        }

        // Merge account analytics (source + destination)
        analyticsParameters.merge(buildAccountAnalyticsParameters()) { $1 }

        Analytics.log(
            event: event,
            params: analyticsParameters,
            analyticsSystems: .all
        )
    }

    private func logSendWithSwapFinishScreenOpened() {
        var analyticsParameters: [Analytics.ParameterKey: String] = [:]

        if let selectedFee = sendFeeInput?.selectedFee {
            let parameter = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee.option)
            analyticsParameters[.feeType] = parameter.rawValue
        }

        if let source = sendSourceTokenInput?.sourceToken {
            analyticsParameters[.sendToken] = source.tokenItem.currencySymbol
            analyticsParameters[.sendBlockchain] = source.tokenItem.blockchain.displayName
        }

        if let tokenFee = sendFeeInput?.selectedFee {
            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)
        }

        if let receive = sendReceiveTokenInput?.receiveToken.receiveToken {
            analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
            analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        if let provider = sendSwapProvidersInput?.selectedExpressProvider {
            analyticsParameters[.provider] = provider.provider.name
        }

        // Merge account analytics (source + destination)
        analyticsParameters.merge(buildAccountAnalyticsParameters()) { $1 }

        Analytics.log(
            event: .sendSendWithSwapInProgressScreenOpened,
            params: analyticsParameters,
            analyticsSystems: .all
        )
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonSendAnalyticsLogger: SendBaseViewAnalyticsLogger {
    func logRequestSupport() {
        Analytics.log(.requestSupport, params: [.source: .send])
    }

    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {
        Analytics.log(.sendButtonClose, params: [
            .source: stepType.analyticsSourceParameterValue,
            .fromSummary: .affirmativeOrNegative(for: stepType.isSummary),
            .valid: .affirmativeOrNegative(for: isAvailableToAction),
        ])
    }

    func logSendBaseViewOpened() {}

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
}

// MARK: - SendManagementModelAnalyticsLogger

extension CommonSendAnalyticsLogger: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError) {
        Analytics.log(event: .sendErrorTransactionRejected, params: [
            .token: tokenItem.currencySymbol,
            .errorCode: "\(error.universalErrorCode)",
            .errorDescription: error.localizedDescription,
            .blockchain: tokenItem.blockchain.displayName,
            .selectedHost: error.formattedLastRetryHost ?? "",
        ])
    }

    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    ) {
        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: fee)

        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
        let additionalFieldAnalyticsParameter: Analytics.ParameterValue = switch additionalField {
        case .none, .notSupported: .null
        case .empty: .empty
        case .filled: .full
        }

        var sourceValue = sendType.analytics

        if case .swap = sendReceiveTokenInput?.receiveToken {
            sourceValue = .sendAndSwap
        }

        var params: [Analytics.ParameterKey: String] = [
            .source: sourceValue.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter.rawValue,
            .walletForm: signerType,
            .selectedHost: currentProviderHost,
        ]

        if let tokenFeeTokenitem = tokenFee?.tokenItem {
            params[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFeeTokenitem)
        }

        Analytics.log(event: .transactionSent, params: params, analyticsSystems: .all)

        switch amount?.type {
        case .none: break
        case .typical: Analytics.log(.sendSelectedCurrency, params: [.type: .token])
        case .alternative: Analytics.log(.sendSelectedCurrency, params: [.type: .selectedCurrencyApp])
        }
    }
}

// MARK: - SendAnalyticsLogger

extension CommonSendAnalyticsLogger: SendAnalyticsLogger {
    func setup(sendDestinationInput: any SendDestinationInput) {
        self.sendDestinationInput = sendDestinationInput
    }

    func setup(sendFeeInput: any SendFeeInput) {
        self.sendFeeInput = sendFeeInput
    }

    func setup(sendSourceTokenInput: any SendSourceTokenInput) {
        self.sendSourceTokenInput = sendSourceTokenInput
    }

    func setup(sendReceiveTokenInput: any SendReceiveTokenInput) {
        self.sendReceiveTokenInput = sendReceiveTokenInput
    }

    func setup(sendSwapProvidersInput: any SendSwapProvidersInput) {
        self.sendSwapProvidersInput = sendSwapProvidersInput
    }
}

// MARK: - SendAnalyticsLogger + Type

extension CommonSendAnalyticsLogger {
    enum SendType {
        case send
        case sell
        case nft
        case sendAndSwap

        var analytics: Analytics.ParameterValue {
            switch self {
            case .send: .send
            case .sell: .sell
            case .nft: .nft
            case .sendAndSwap: .sendAndSwap
            }
        }
    }
}
