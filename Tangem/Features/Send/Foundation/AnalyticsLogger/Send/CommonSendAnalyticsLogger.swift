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

    private let sendType: SendType
    private let coordinatorSource: SendCoordinator.Source
    private var destinationAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    private var sourceTokenItem: TokenItem? {
        sendSourceTokenInput?.sourceToken.value?.tokenItem
    }

    private var receiveTokenItem: TokenItem? {
        sendReceiveTokenInput?.receiveToken.value?.tokenItem
    }

    private var feeTokenItem: TokenItem? {
        sendFeeInput?.selectedFee?.tokenItem
    }

    private var sourceFlow: Analytics.ParameterValue {
        switch sendType {
        case .send where isSwap: .sendAndSwap
        case .sell, .nft, .send: .send
        case .swap: .swap
        }
    }

    private var isSwap: Bool {
        sendReceiveTokenInput?.receiveToken.value != nil
    }

    private func buildEntryTypeParameterValue() -> Analytics.ParameterValue {
        coordinatorSource == .qrScan ? .qr : .manually
    }

    init(sendType: SendType, coordinatorSource: SendCoordinator.Source = .main) {
        self.sendType = sendType
        self.coordinatorSource = coordinatorSource
    }

    private func buildRateTypeAnalyticsValue() -> String? {
        sendSwapProvidersInput?.currentRateType?.analyticsValue.rawValue
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

    private func buildSwapTokenParams() -> [Analytics.ParameterKey: String] {
        var params: [Analytics.ParameterKey: String] = [:]

        if let sourceTokenItem {
            params[.sendToken] = sourceTokenItem.currencySymbol
            params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
        }

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            params[.receiveToken] = receive.tokenItem.currencySymbol
            params[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        return params
    }

    private func buildSwapTokenProviderParams() -> [Analytics.ParameterKey: String] {
        var params = buildSwapTokenParams()

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            params[.provider] = provider.provider.name
        }

        return params
    }
}

// MARK: - SendDestinationAnalyticsLogger

extension CommonSendAnalyticsLogger: SendDestinationAnalyticsLogger {
    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?) {
        destinationAnalyticsProvider = analyticsProvider
    }

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

        let event: Analytics.Event = switch sourceTokenItem?.token?.metadata.kind {
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
        guard let tokenItem = sourceTokenItem else {
            return
        }

        Analytics.log(
            event: .sendCustomFeeClicked,
            params: [.token: tokenItem.currencySymbol, .blockchain: tokenItem.blockchain.displayName]
        )
    }

    func logFeeSummaryOpened() {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        Analytics.log(
            event: .sendFeeSummaryScreenOpened,
            params: [
                .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
                .blockchain: tokenItem.blockchain.displayName,
            ]
        )
    }

    func logFeeTokensOpened(availableTokenFees: [TokenFee]) {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        let availableFeeParam = availableTokenFees.map { SendAnalyticsHelper.makeAnalyticsTokenName(from: $0.tokenItem) }.joined(separator: ", ")

        Analytics.log(
            event: .sendFeeTokenScreenOpened,
            params: [.availableFee: availableFeeParam, .blockchain: tokenItem.blockchain.displayName]
        )
    }

    func logFeeStepOpened() {
        guard let tokenItem = sourceTokenItem else {
            return
        }

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
        switch sourceTokenItem?.token?.metadata.kind {
        case .nonFungible:
            Analytics.log(.nftCommissionScreenOpened)
        case .fungible, .none:
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        }
    }

    func logFeeSelected(tokenFee: TokenFee) {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        let feeTypeParam = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: tokenFee.option, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
        let blockchainParam = tokenFee.tokenItem.blockchain.displayName

        if case .nonFungible = tokenItem.token?.metadata.kind {
            Analytics.log(
                event: .nftFeeSelected,
                params: [.feeType: feeTypeParam.rawValue, .blockchain: blockchainParam, .source: sourceFlow.rawValue]
            )
        } else {
            let feeTokenParam = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)
            let params: [Analytics.ParameterKey: String] = [
                .feeToken: feeTokenParam,
                .feeType: feeTypeParam.rawValue,
                .source: sourceFlow.rawValue,
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

        let feeType = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: feeOption, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)
        let event: Analytics.Event
        let source: Analytics.ParameterValue?

        switch sourceTokenItem?.token?.metadata.kind {
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
        guard let feeTokenItem else {
            return
        }

        Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
            .token: feeTokenItem.currencySymbol,
        ])
    }
}

// MARK: - SendAmountAnalyticsLogger

extension CommonSendAnalyticsLogger: SendAmountAnalyticsLogger {
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
        switch sendType {
        case .send where isSwap:
            logSendWithSwapAmountScreenOpened(rateType: nil)
        default:
            Analytics.log(
                .sendAmountScreenOpened,
                params: [.source: sourceFlow, .type: buildEntryTypeParameterValue()],
                analyticsSystems: .all
            )
        }
    }

    func logAmountStepReopened() {
        switch sendType {
        case .send where isSwap:
            logSendWithSwapAmountScreenOpened(rateType: nil)
        default:
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        }
    }

    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue) {
        switch sendType {
        case .send where isSwap:
            var params: [Analytics.ParameterKey: String] = [.screen: screen.rawValue]
            if let sourceTokenItem {
                params[.sendToken] = sourceTokenItem.currencySymbol
                params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
            }
            Analytics.log(event: .sendSwapErrorInsufficientBalance, params: params)
        default:
            break
        }
    }

    func logSwapErrorMinAmount(screen: Analytics.ParameterValue) {
        switch sendType {
        case .send where isSwap:
            var params: [Analytics.ParameterKey: String] = [.screen: screen.rawValue]
            if let sourceTokenItem {
                params[.sendToken] = sourceTokenItem.currencySymbol
                params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
            }
            Analytics.log(event: .sendSwapErrorMinAmount, params: params)
        default:
            break
        }
    }

    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue) {
        switch sendType {
        case .send where isSwap:
            var params: [Analytics.ParameterKey: String] = [.screen: screen.rawValue]
            if let sourceTokenItem {
                params[.sendToken] = sourceTokenItem.currencySymbol
                params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
            }
            Analytics.log(event: .sendSwapErrorMaxAmount, params: params)
        default:
            break
        }
    }

    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {
        switch sendType {
        case .send where isSwap:
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
        default:
            break
        }
    }

    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {
        switch sendType {
        case .send where isSwap:
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
        default:
            break
        }
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

extension CommonSendAnalyticsLogger: SendSummaryAnalyticsLogger {
    func logSummaryStepOpened() {
        switch sendType {
        case .send where isSwap:
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

        case .send:
            var params: [Analytics.ParameterKey: String] = [
                .source: sourceFlow.rawValue,
                .type: buildEntryTypeParameterValue().rawValue,
            ]

            if let tokenItem = sourceTokenItem {
                params[.token] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem)
                params[.blockchain] = tokenItem.blockchain.displayName
            }

            if let tokenFeeTokenItem = sendFeeInput?.selectedFee?.tokenItem {
                params[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFeeTokenItem)
            }

            Analytics.log(event: .sendConfirmScreenOpened, params: params, analyticsSystems: .all)

        case .swap:
            var params: [Analytics.ParameterKey: String] = [:]

            if let tokenItem = sourceTokenItem ?? sendReceiveTokenInput?.receiveToken.value?.tokenItem {
                params[.token] = tokenItem.currencySymbol
                params[.blockchain] = tokenItem.blockchain.displayName
            }

            Analytics.log(event: .swapScreenOpenedSwap, params: params)

        case .nft:
            var params: [Analytics.ParameterKey: String] = [:]

            if let tokenItem = sourceTokenItem {
                params[.blockchain] = tokenItem.blockchain.displayName
            }

            Analytics.log(event: .nftConfirmScreenOpened, params: params)

        default:
            break
        }
    }

    func logUserDidTapOnValidator() {}
    func logUserDidTapOnProvider() {
        Analytics.log(.sendProviderClicked)
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

extension CommonSendAnalyticsLogger: SendApproveAnalyticsLogger {
    func logPermissionScreenOpened(isRevoke: Bool) {
        let event: Analytics.Event = isRevoke ? .swapPermissionUpdateScreenOpened : .swapPermissionScreenOpened
        Analytics.log(event: event, params: buildSwapTokenProviderParams())
    }

    func logSwapButtonPermissionApprove(policy: ApprovePolicy) {
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .sendToken: sourceTokenItem.currencySymbol,
            .sendBlockchain: sourceTokenItem.blockchain.displayName,
        ]

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            analyticsParameters[.provider] = provider.provider.name
        }

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
            analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        analyticsParameters[.type] = switch policy {
        case .specified: Analytics.ParameterValue.oneTransactionApprove.rawValue
        case .unlimited: Analytics.ParameterValue.unlimitedApprove.rawValue
        }

        Analytics.log(event: .swapButtonPermissionApprove, params: analyticsParameters)
    }

    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        let permissionType: Analytics.ParameterValue = switch policy {
        case .specified: .oneTransactionApprove
        case .unlimited: .unlimitedApprove
        }

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceApprove.rawValue,
            .feeType: Analytics.ParameterValue.transactionFeeMax.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.blockchain.displayName,
            .permissionType: permissionType.rawValue,
            .walletForm: signerType,
            .selectedHost: currentProviderHost,
        ], analyticsSystems: .all)
    }
}

// MARK: - SendFinishAnalyticsLogger

extension CommonSendAnalyticsLogger: SwapManagementModelAnalyticsLogger {
    func logSwapButtonSwap() {
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

        Analytics.log(event: .swapButtonSwap, params: analyticsParameters)
    }

    func logSwapButtonTransfer() {
        Analytics.log(event: .swapButtonTransfer, params: buildSwapTokenParams())
    }

    func logSwapTransferModeSwitched() {
        Analytics.log(event: .swapTransferModeSwitched, params: buildSwapTokenParams())
    }

    func logSwapPreselectedTokenChanged(
        direction: Analytics.ParameterValue,
        preselectedSymbol: String,
        selectedSymbol: String
    ) {
        Analytics.log(event: .swapPreselectedTokenChanged, params: [
            .direction: direction.rawValue,
            .preselectedToken: preselectedSymbol,
            .selectedToken: selectedSymbol,
        ])
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

extension CommonSendAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        switch sendReceiveTokenInput?.receiveToken.value {
        case .none:
            logSendFinishScreenOpened(
                destinationDidResolved: sendDestinationInput?.destination?.value.isResolved ?? false
            )
        case .some where sendType == .swap:
            logSwapFinishScreenOpened()
        case .some:
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
        guard let tokenItem = sourceTokenItem else {
            return
        }

        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSentScreenOpened
        default: .sendTransactionSentScreenOpened
        }

        let feeTypeAnalyticsParameter = SendAnalyticsHelper.makeFeeTypeParameter(selectedFee: sendFeeInput?.selectedFee?.option, supportFeeSelection: sendFeeInput?.supportFeeSelection ?? false)

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeTypeAnalyticsParameter.rawValue,
            .ensAddress: Analytics.ParameterValue.boolState(for: destinationDidResolved).rawValue,
        ]

        if let selectedFee = sendFeeInput?.selectedFee {
            if let parameters = selectedFee.value.value?.parameters as? EthereumFeeParameters {
                let hasNonce = parameters.nonce != nil
                analyticsParameters[.nonce] = Analytics.ParameterValue.affirmativeOrNegative(for: hasNonce).rawValue
            }

            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: selectedFee.tokenItem)
            let isGasless = selectedFee.value.value?.isGasless ?? false
            analyticsParameters[.feeAssetType] = Analytics.ParameterValue.feeAssetType(isGasless: isGasless).rawValue
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
        logFinishScreenWithSwapParameters(event: .sendSendWithSwapInProgressScreenOpened)
    }

    private func logSwapFinishScreenOpened() {
        let isTransfer = sourceTokenItem?.expressCurrency == receiveTokenItem?.expressCurrency
        let event: Analytics.Event = isTransfer ? .swapTransferInProgressScreenOpened : .swapSwapInProgressScreenOpened
        logFinishScreenWithSwapParameters(event: event)
    }

    private func logFinishScreenWithSwapParameters(event: Analytics.Event) {
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

        // Merge account analytics (source + destination)
        analyticsParameters.merge(buildAccountAnalyticsParameters()) { $1 }

        Analytics.log(
            event: event,
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

    func logSendBaseViewOpened() {
        guard case .send = sendType else {
            return
        }

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

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {
        switch (sendType, flow, type) {
        case (.send, .send, .action) where isSwap:
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

            // Merge account analytics (source + destination)
            analyticsParameters.merge(buildAccountAnalyticsParameters()) { $1 }

            Analytics.log(
                event: .sendButtonSendWithSwap,
                params: analyticsParameters,
                analyticsSystems: .all
            )
        default:
            break
        }
    }
}

// MARK: - SendManagementModelAnalyticsLogger

extension CommonSendAnalyticsLogger: SendManagementModelAnalyticsLogger {
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

        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
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
        case swap

        var analytics: Analytics.ParameterValue {
            switch self {
            case .send: .send
            case .sell: .sell
            case .nft: .nft
            case .swap: .swap
            }
        }
    }
}

extension ExpressProviderRateType {
    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .fixed: Analytics.ParameterValue.fixed
        case .float: Analytics.ParameterValue.float
        }
    }
}
