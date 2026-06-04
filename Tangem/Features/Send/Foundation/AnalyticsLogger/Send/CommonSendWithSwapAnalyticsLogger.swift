//
//  CommonSendWithSwapAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

/// Dedicated logger for the send-with-swap flow.
///
/// It owns the send-with-swap specific events (`.source == .sendAndSwap`, `sendSendWithSwap*`,
/// `sendButtonSendWithSwap`, `sendSwapError*`) and delegates the events that are identical to the
/// pure swap flow to `CommonSwapAnalyticsLogger`, so that behaviour stays shared between flows.
class CommonSendWithSwapAnalyticsLogger {
    private weak var sendDestinationInput: SendDestinationInput?
    private weak var sendFeeInput: SendFeeInput?
    private weak var sendSourceTokenInput: SendSourceTokenInput?
    private weak var sendReceiveTokenInput: SendReceiveTokenInput?
    private weak var sendSwapProvidersInput: SendSwapProvidersInput?

    private let coordinatorSource: SendCoordinator.Source
    private let swapAnalyticsLogger: CommonSwapAnalyticsLogger
    private var destinationAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    private var sourceFlow: Analytics.ParameterValue {
        switch sendReceiveTokenInput?.receiveToken.value {
        case .none: .send
        case .some: .sendAndSwap
        }
    }

    private var sourceTokenItem: TokenItem? {
        sendSourceTokenInput?.sourceToken.value?.tokenItem
    }

    init(
        coordinatorSource: SendCoordinator.Source,
        swapAnalyticsLogger: CommonSwapAnalyticsLogger
    ) {
        self.coordinatorSource = coordinatorSource
        self.swapAnalyticsLogger = swapAnalyticsLogger
    }

    private func buildRateTypeAnalyticsValue() -> String? {
        sendSwapProvidersInput?.currentRateType?.analyticsValue.rawValue
    }

    private func buildEntryTypeParameterValue() -> Analytics.ParameterValue {
        coordinatorSource == .qrScan ? .qr : .manually
    }

    private func buildAccountAnalyticsParameters() -> [Analytics.ParameterKey: String] {
        var result: [Analytics.ParameterKey: String] = [:]

        if let sourceAccount = sendSourceTokenInput?.sourceToken.value?.accountModelAnalyticsProvider {
            result.enrich(with: sourceAccount.analyticsParameters(with: PairedAccountAnalyticsBuilder(role: .source)))
        }

        if let destinationAnalyticsProvider {
            result.enrich(with: destinationAnalyticsProvider.analyticsParameters(with: PairedAccountAnalyticsBuilder(role: .destination)))
        }

        return result
    }
}

// MARK: - SendWithSwapAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendWithSwapAnalyticsLogger {
    func setup(sendDestinationInput: any SendDestinationInput) {
        self.sendDestinationInput = sendDestinationInput
    }

    func setup(sendFeeInput: any SendFeeInput) {
        self.sendFeeInput = sendFeeInput
        swapAnalyticsLogger.setup(sendFeeInput: sendFeeInput)
    }

    func setup(sendSourceTokenInput: any SendSourceTokenInput) {
        self.sendSourceTokenInput = sendSourceTokenInput
        swapAnalyticsLogger.setup(sendSourceTokenInput: sendSourceTokenInput)
    }

    func setup(sendReceiveTokenInput: any SendReceiveTokenInput) {
        self.sendReceiveTokenInput = sendReceiveTokenInput
        swapAnalyticsLogger.setup(sendReceiveTokenInput: sendReceiveTokenInput)
    }

    func setup(sendSwapProvidersInput: any SendSwapProvidersInput) {
        self.sendSwapProvidersInput = sendSwapProvidersInput
        swapAnalyticsLogger.setup(sendSwapProvidersInput: sendSwapProvidersInput)
    }
}

// MARK: - SendDestinationAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendDestinationAnalyticsLogger {
    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?) {
        destinationAnalyticsProvider = analyticsProvider
    }

    func logDestinationStepOpened() {
        Analytics.log(.sendAddressScreenOpened, params: [.source: sourceFlow], analyticsSystems: .all)
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

        Analytics.log(
            .sendAddressEntered,
            params: [
                .method: parameterValue,
                .validation: isAddressValid ? .success : .fail,
                .source: sourceFlow,
            ]
        )
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendBaseViewAnalyticsLogger {
    func logSendBaseViewOpened() {
        var params: [Analytics.ParameterKey: String] = [
            .source: sourceFlow.rawValue,
            .type: buildEntryTypeParameterValue().rawValue,
        ]

        if let tokenItem = sourceTokenItem {
            params[.token] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem)
            params[.blockchain] = tokenItem.blockchain.displayName
        }

        Analytics.log(event: .sendScreenOpened, params: params, analyticsSystems: .all)
    }

    func logRequestSupport() {
        swapAnalyticsLogger.logRequestSupport()
    }

    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {
        swapAnalyticsLogger.logCloseButton(stepType: stepType, isAvailableToAction: isAvailableToAction)
    }

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {
        guard flow == .send, type == .action, let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .sendToken: sourceTokenItem.currencySymbol,
            .sendBlockchain: sourceTokenItem.blockchain.displayName,
        ]

        if let selectedFee = sendFeeInput?.selectedFee {
            let parameter = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: selectedFee.option, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
            analyticsParameters[.feeType] = parameter.rawValue
            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: selectedFee.tokenItem)
        }

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
            analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            analyticsParameters[.provider] = provider.provider.name
        }

        if let rateType = buildRateTypeAnalyticsValue() {
            analyticsParameters[.rateType] = rateType
        }

        analyticsParameters.merge(buildAccountAnalyticsParameters()) { $1 }

        Analytics.log(event: .sendButtonSendWithSwap, params: analyticsParameters, analyticsSystems: .all)
    }
}

// MARK: - SendAmountAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendAmountAnalyticsLogger {
    func logTapMaxAmount() {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        Analytics.log(event: .sendMaxAmountTapped, params: [
            .source: sourceFlow.rawValue,
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }

    func logTapConvertToAnotherToken() {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        Analytics.log(event: .sendButtonConvertToken, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }

    func logAmountStepOpened() {
        logSendWithSwapAmountScreenOpened(rateType: nil)
    }

    func logAmountStepReopened() {
        logSendWithSwapAmountScreenOpened(rateType: nil)
    }

    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue) {
        var params: [Analytics.ParameterKey: String] = [.screen: screen.rawValue]
        if let sourceTokenItem {
            params[.sendToken] = sourceTokenItem.currencySymbol
            params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
        }
        Analytics.log(event: .sendSwapErrorInsufficientBalance, params: params)
    }

    func logSwapErrorMinAmount(screen: Analytics.ParameterValue) {
        var params: [Analytics.ParameterKey: String] = [.screen: screen.rawValue]
        if let sourceTokenItem {
            params[.sendToken] = sourceTokenItem.currencySymbol
            params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
        }
        Analytics.log(event: .sendSwapErrorMinAmount, params: params)
    }

    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue) {
        var params: [Analytics.ParameterKey: String] = [.screen: screen.rawValue]
        if let sourceTokenItem {
            params[.sendToken] = sourceTokenItem.currencySymbol
            params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
        }
        Analytics.log(event: .sendSwapErrorMaxAmount, params: params)
    }

    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {
        var params: [Analytics.ParameterKey: String] = [
            .screen: screen.rawValue,
            .swapErrorDescription: errorDescription,
        ]
        if let sourceTokenItem {
            params[.sendToken] = sourceTokenItem.currencySymbol
            params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
        }
        if let receive = sendReceiveTokenInput?.receiveToken.value {
            params[.receiveToken] = receive.tokenItem.currencySymbol
            params[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }
        Analytics.log(event: .sendSwapErrorExpressQuote, params: params)
    }

    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .sendToken: sourceTokenItem.currencySymbol,
            .sendBlockchain: sourceTokenItem.blockchain.displayName,
        ]

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
            analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            analyticsParameters[.provider] = provider.provider.name
        }

        if let rateType = rateType?.analyticsValue.rawValue ?? buildRateTypeAnalyticsValue() {
            analyticsParameters[.rateType] = rateType
        }

        Analytics.log(event: .sendSendWithSwapAmountScreenOpened, params: analyticsParameters, analyticsSystems: .all)
    }
}

// MARK: - SendFeeAnalyticsLogger, FeeSelectorAnalytics

extension CommonSendWithSwapAnalyticsLogger: SendFeeAnalyticsLogger, FeeSelectorAnalytics {
    func logCustomFeeClicked() {
        swapAnalyticsLogger.logCustomFeeClicked()
    }

    func logFeeSummaryOpened() {
        swapAnalyticsLogger.logFeeSummaryOpened()
    }

    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {
        swapAnalyticsLogger.logFeeTokensOpened(availableTokenFees: availableTokenFees)
    }

    func logFeeStepOpened() {
        swapAnalyticsLogger.logFeeStepOpened()
    }

    func logFeeStepReopened() {
        swapAnalyticsLogger.logFeeStepReopened()
    }

    func logSendNoticeTransactionDelaysArePossible() {
        swapAnalyticsLogger.logSendNoticeTransactionDelaysArePossible()
    }

    func logFeeSelected(tokenFee: TokenFee) {
        let feeTypeParam = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: tokenFee.option, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
        let blockchainParam = tokenFee.tokenItem.blockchain.displayName
        let feeTokenParam = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)

        let params: [Analytics.ParameterKey: String] = [
            .feeToken: feeTokenParam,
            .feeType: feeTypeParam.rawValue,
            .source: sourceFlow.rawValue,
            .blockchain: blockchainParam,
        ]

        Analytics.log(event: .sendFeeSelected, params: params)
    }

    func logFeeSelected(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
            return
        }

        let feeType = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: feeOption, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
        let params: [Analytics.ParameterKey: String] = [
            .feeType: feeType.rawValue,
            .source: sourceFlow.rawValue,
        ]

        Analytics.log(event: .sendFeeSelected, params: params)
    }
}

// MARK: - SendSwapProvidersAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendSwapProvidersAnalyticsLogger {
    func logSendSwapProvidersChosen(provider: ExpressProvider) {
        swapAnalyticsLogger.logSendSwapProvidersChosen(provider: provider)
    }
}

// MARK: - SendReceiveTokensListAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendReceiveTokensListAnalyticsLogger {
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
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .sendToken: sourceTokenItem.currencySymbol,
            .sendBlockchain: sourceTokenItem.blockchain.displayName,
            .receiveToken: token,
        ]

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            analyticsParameters[.provider] = provider.provider.name
        }

        Analytics.log(event: .sendNoticeCantSwapThisToken, params: analyticsParameters)
    }
}

// MARK: - SendSummaryAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendSummaryAnalyticsLogger {
    func logSummaryStepOpened() {
        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .source: sourceFlow.rawValue,
            .type: buildEntryTypeParameterValue().rawValue,
        ]

        if let tokenItem = sourceTokenItem {
            analyticsParameters[.sendToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem)
            analyticsParameters[.sendBlockchain] = tokenItem.blockchain.displayName
        }

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
            analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            analyticsParameters[.provider] = provider.provider.name
        }

        if let rateType = buildRateTypeAnalyticsValue() {
            analyticsParameters[.rateType] = rateType
        }

        Analytics.log(event: .sendSendWithSwapConfirmScreenOpened, params: analyticsParameters, analyticsSystems: .all)
    }

    func logUserDidTapOnValidator() {}

    func logUserDidTapOnProvider() {
        swapAnalyticsLogger.logUserDidTapOnProvider()
    }

    func logTapAmountFraction(_ fraction: SwapAmountFraction) {
        guard let tokenItem = sourceTokenItem else { return }

        Analytics.log(event: .swapFastAmountInput, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .percentage: fraction.analyticsValue,
        ])
    }

    func logSwapTypeReselection(from: SwapFormVariant, to: SwapFormVariant) {
        Analytics.log(event: .swapTypeReselection, params: [
            .typeFrom: from.analyticsValue.rawValue,
            .typeTo: to.analyticsValue.rawValue,
        ])
    }

    func logSwapTypeScreenOpened(variant: SwapFormVariant) {
        Analytics.log(event: .swapTypeSimpleDetailed, params: [
            .swapType: variant.analyticsValue.rawValue,
        ])
    }
}

// MARK: - SendApproveAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendApproveAnalyticsLogger {
    func logPermissionScreenOpened(isRevoke: Bool) {
        swapAnalyticsLogger.logPermissionScreenOpened(isRevoke: isRevoke)
    }

    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy) {
        swapAnalyticsLogger.logSwapButtonPermissionApprove(policy: policy)
    }

    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {
        swapAnalyticsLogger.logApproveTransactionSent(
            policy: policy,
            signerType: signerType,
            currentProviderHost: currentProviderHost
        )
    }
}

// MARK: - SwapManagementModelAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SwapManagementModelAnalyticsLogger {
    func logSwapButtonSwap() {
        swapAnalyticsLogger.logSwapButtonSwap()
    }

    func logSwapButtonTransfer() {
        swapAnalyticsLogger.logSwapButtonTransfer()
    }

    func logSwapTransferModeSwitched() {
        swapAnalyticsLogger.logSwapTransferModeSwitched()
    }

    func logSwapPreselectedTokenChanged(
        direction: Analytics.ParameterValue,
        preselectedSymbol: String,
        selectedSymbol: String
    ) {
        swapAnalyticsLogger.logSwapPreselectedTokenChanged(
            direction: direction,
            preselectedSymbol: preselectedSymbol,
            selectedSymbol: selectedSymbol
        )
    }

    func logSwapTransactionSent(result: TransactionDispatcherResult) {
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .source: sourceFlow.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: sourceTokenItem),
            .blockchain: sourceTokenItem.blockchain.displayName,
            .walletForm: result.signerType,
            .selectedHost: result.currentHost,
        ]

        if let selectedFee = sendFeeInput?.selectedFee {
            let parameter = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: selectedFee.option, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
            analyticsParameters[.feeType] = parameter.rawValue
            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: selectedFee.tokenItem)
            let isGasless = selectedFee.value.value?.isGasless ?? false
            analyticsParameters[.feeAssetType] = Analytics.ParameterValue.feeAssetType(isGasless: isGasless).rawValue
        }

        Analytics.log(event: .transactionSent, params: analyticsParameters, analyticsSystems: .all)
    }
}

// MARK: - SendFinishAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .sendToken: sourceTokenItem.currencySymbol,
            .sendBlockchain: sourceTokenItem.blockchain.displayName,
        ]

        if let selectedFee = sendFeeInput?.selectedFee {
            let parameter = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: selectedFee.option, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
            analyticsParameters[.feeType] = parameter.rawValue
            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: selectedFee.tokenItem)
            let isGasless = selectedFee.value.value?.isGasless ?? false
            analyticsParameters[.feeAssetType] = Analytics.ParameterValue.feeAssetType(isGasless: isGasless).rawValue
        }

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
            analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            analyticsParameters[.provider] = provider.provider.name
        }

        if let rateType = buildRateTypeAnalyticsValue() {
            analyticsParameters[.rateType] = rateType
        }

        analyticsParameters.merge(buildAccountAnalyticsParameters()) { $1 }

        Analytics.log(event: .sendSendWithSwapInProgressScreenOpened, params: analyticsParameters, analyticsSystems: .all)
    }

    func logShareButton() {
        swapAnalyticsLogger.logShareButton()
    }

    func logExploreButton() {
        swapAnalyticsLogger.logExploreButton()
    }
}

// MARK: - SendManagementModelAnalyticsLogger

extension CommonSendWithSwapAnalyticsLogger: SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError) {
        guard let tokenItem = sourceTokenItem else {
            return
        }

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
        guard let tokenItem = sourceTokenItem else {
            return
        }

        let feeType = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: fee, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)

        let additionalFieldAnalyticsParameter: Analytics.ParameterValue = switch additionalField {
        case .none, .notSupported: .null
        case .empty: .empty
        case .filled: .full
        }

        var params: [Analytics.ParameterKey: String] = [
            .source: sourceFlow.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter.rawValue,
            .walletForm: signerType,
            .selectedHost: currentProviderHost,
        ]

        if let tokenFee = tokenFee {
            params[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)
            let isGasless = tokenFee.value.value?.isGasless ?? false
            params[.feeAssetType] = Analytics.ParameterValue.feeAssetType(isGasless: isGasless).rawValue
        }

        Analytics.log(event: .transactionSent, params: params, analyticsSystems: .all)

        switch amount?.type {
        case .none: break
        case .typical: Analytics.log(.sendSelectedCurrency, params: [.type: .token])
        case .alternative: Analytics.log(.sendSelectedCurrency, params: [.type: .selectedCurrencyApp])
        }
    }
}
