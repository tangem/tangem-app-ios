//
//  CommonSwapSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

class CommonSwapSendAnalyticsLogger {
    private weak var sendFeeInput: SendFeeInput?
    private weak var sendSourceTokenInput: SendSourceTokenInput?
    private weak var sendReceiveTokenInput: SendReceiveTokenInput?
    private weak var sendSwapProvidersInput: SendSwapProvidersInput?

    private var sourceTokenItem: TokenItem? {
        sendSourceTokenInput?.sourceToken.value?.tokenItem
    }

    private var feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder {
        let supportFeeSelection = sendFeeInput?.supportFeeSelection ?? false
        return FeeAnalyticsParameterBuilder(supportFeeSelection: supportFeeSelection)
    }

    private var rateTypeAnalyticsValue: String? {
        sendSwapProvidersInput?.currentRateType?.analyticsValue.rawValue
    }
}

// MARK: - SwapSendAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SwapSendAnalyticsLogger {
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

// MARK: - SendBaseViewAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SendBaseViewAnalyticsLogger {
    func logSendBaseViewOpened() {}

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

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
}

// MARK: - SendAmountAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SendAmountAnalyticsLogger {
    func logTapMaxAmount() {
        guard let tokenItem = sourceTokenItem else {
            return
        }

        Analytics.log(event: .sendMaxAmountTapped, params: [
            .source: Analytics.ParameterValue.swap.rawValue,
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }

    func logTapConvertToAnotherToken() {}

    func logAmountStepOpened() {}

    func logAmountStepReopened() {}
}

// MARK: - SendFeeAnalyticsLogger, FeeSelectorAnalytics

extension CommonSwapSendAnalyticsLogger: SendFeeAnalyticsLogger, FeeSelectorAnalytics {
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

        Analytics.log(
            event: .sendFeeScreenOpened,
            params: [
                .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
                .blockchain: tokenItem.blockchain.displayName,
            ]
        )
    }

    func logFeeStepReopened() {
        Analytics.log(.sendScreenReopened, params: [.source: .fee])
    }

    func logFeeSelected(tokenFee: TokenFee) {
        let feeTypeParam = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: tokenFee.option)
        let blockchainParam = tokenFee.tokenItem.blockchain.displayName
        let feeTokenParam = SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenFee.tokenItem)

        let params: [Analytics.ParameterKey: String] = [
            .feeToken: feeTokenParam,
            .feeType: feeTypeParam.rawValue,
            .source: Analytics.ParameterValue.swap.rawValue,
            .blockchain: blockchainParam,
        ]

        Analytics.log(event: .sendFeeSelected, params: params)
    }

    func logFeeSelected(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
            return
        }

        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: feeOption)
        let params: [Analytics.ParameterKey: String] = [
            .feeType: feeType.rawValue,
            .source: Analytics.ParameterValue.swap.rawValue,
        ]

        Analytics.log(event: .sendFeeSelected, params: params)
    }

    func logSendNoticeTransactionDelaysArePossible() {
        guard let feeTokenItem = sendFeeInput?.selectedFee?.tokenItem else {
            return
        }

        Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
            .token: feeTokenItem.currencySymbol,
        ])
    }
}

// MARK: - SendSwapProvidersAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SendSwapProvidersAnalyticsLogger {
    func logSendSwapProvidersChosen(provider: ExpressProvider) {
        Analytics.log(event: .sendProviderChosen, params: [.provider: provider.name])
    }
}

// MARK: - SendSummaryAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SendSummaryAnalyticsLogger {
    func logSummaryStepOpened() {
        var params: [Analytics.ParameterKey: String] = [:]

        if let tokenItem = sourceTokenItem ?? sendReceiveTokenInput?.receiveToken.value?.tokenItem {
            params[.token] = tokenItem.currencySymbol
            params[.blockchain] = tokenItem.blockchain.displayName
        }

        Analytics.log(event: .swapScreenOpenedSwap, params: params)
    }

    func logUserDidTapOnValidator() {}

    func logUserDidTapOnProvider() {
        Analytics.log(.sendProviderClicked)
    }
}

// MARK: - SendApproveAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SendApproveAnalyticsLogger {
    func logPermissionScreenOpened(isRevoke: Bool) {
        var params: [Analytics.ParameterKey: String] = [:]

        if let sourceTokenItem {
            params[.sendToken] = sourceTokenItem.currencySymbol
            params[.sendBlockchain] = sourceTokenItem.blockchain.displayName
        }

        if let receive = sendReceiveTokenInput?.receiveToken.value {
            params[.receiveToken] = receive.tokenItem.currencySymbol
            params[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
        }

        if let provider = sendSwapProvidersInput?.selectedExpressProvider?.value {
            params[.provider] = provider.provider.name
        }

        let event: Analytics.Event = isRevoke ? .swapPermissionUpdateScreenOpened : .swapPermissionScreenOpened
        Analytics.log(event: event, params: params)
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

// MARK: - SwapManagementModelAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SwapManagementModelAnalyticsLogger {
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

    func logSwapTransactionSent(result: TransactionDispatcherResult) {
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.swap.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: sourceTokenItem),
            .blockchain: sourceTokenItem.blockchain.displayName,
            .walletForm: result.signerType,
            .selectedHost: result.currentHost,
        ]

        if let selectedFee = sendFeeInput?.selectedFee {
            let parameter = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee.option)
            analyticsParameters[.feeType] = parameter.rawValue
            analyticsParameters[.feeToken] = SendAnalyticsHelper.makeAnalyticsTokenName(from: selectedFee.tokenItem)
        }

        Analytics.log(event: .transactionSent, params: analyticsParameters, analyticsSystems: .all)
    }
}

// MARK: - SendFinishAnalyticsLogger

extension CommonSwapSendAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        guard let sourceTokenItem else {
            return
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .sendToken: sourceTokenItem.currencySymbol,
            .sendBlockchain: sourceTokenItem.blockchain.displayName,
        ]

        if let selectedFee = sendFeeInput?.selectedFee {
            let parameter = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee.option)
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

        if let rateType = rateTypeAnalyticsValue {
            analyticsParameters[.rateType] = rateType
        }

        Analytics.log(
            event: .swapSwapInProgressScreenOpened,
            params: analyticsParameters,
            analyticsSystems: .all
        )
    }

    func logShareButton() {
        Analytics.log(.sendButtonShare)
    }

    func logExploreButton() {
        Analytics.log(.sendButtonExplore)
    }
}
