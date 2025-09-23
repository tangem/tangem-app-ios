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
    private weak var sendFeeInput: SendFeeInput?
    private weak var sendSourceTokenInput: SendSourceTokenInput?
    private weak var sendReceiveTokenInput: SendReceiveTokenInput?
    private weak var sendSwapProvidersInput: SendSwapProvidersInput?

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private let sendType: SendType

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
}

// MARK: - SendDestinationAnalyticsLogger

extension CommonSendAnalyticsLogger: SendDestinationAnalyticsLogger {
    func logDestinationStepOpened() {
        Analytics.log(.sendAddressScreenOpened)
    }

    func logDestinationStepReopened() {
        Analytics.log(.sendScreenReopened, params: [.source: .address])
    }

    func logQRScannerOpened() {
        Analytics.log(.sendButtonQRCode)
    }

    func logSendAddressEntered(isAddressValid: Bool, source: Analytics.DestinationAddressSource) {
        guard let parameterValue = source.parameterValue else {
            return
        }

        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSendAddressEntered
        default: .sendAddressEntered
        }

        Analytics.log(
            event,
            params: [
                .source: parameterValue,
                .validation: isAddressValid ? .success : .fail,
            ]
        )
    }
}

// MARK: - SendAnalyticsLogger, FeeSelectorContentViewModelAnalytics

extension CommonSendAnalyticsLogger: SendFeeAnalyticsLogger, FeeSelectorContentViewModelAnalytics {
    func logFeeStepOpened() {
        switch tokenItem.token?.metadata.kind {
        case .fungible, .none:
            Analytics.log(.sendFeeScreenOpened)
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

    func logSendFeeSelected(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
            return
        }

        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: feeOption)
        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .fungible, .none: .sendFeeSelected
        case .nonFungible: .nftFeeSelected
        }

        Analytics.log(event: event, params: [.feeType: feeType.rawValue])
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
        var params: [Analytics.ParameterKey: String] = [:]

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
        Analytics.log(.sendAmountScreenOpened)
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
            Analytics.log(.sendConfirmScreenOpened)
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
            logSendFinishScreenOpened()
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

    private func logSendFinishScreenOpened() {
        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSentScreenOpened
        default: .sendTransactionSentScreenOpened
        }

        let feeTypeAnalyticsParameter = feeAnalyticsParameterBuilder.analyticsParameter(
            selectedFee: sendFeeInput?.selectedFee.option
        )

        let ensTypeAnalyticsParameter: Bool

        if case .ethereum = tokenItem.blockchain {
            ensTypeAnalyticsParameter = true
        } else {
            ensTypeAnalyticsParameter = false
        }

        var analyticsParameters: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeTypeAnalyticsParameter.rawValue,
            .ensAddress: Analytics.ParameterValue.boolState(for: ensTypeAnalyticsParameter).rawValue,
        ]

        if let parameters = sendFeeInput?.selectedFee.value.value?.parameters as? EthereumFeeParameters,
           let nonce = parameters.nonce {
            analyticsParameters[.nonce] = String(nonce)
        }

        Analytics.log(event: event, params: analyticsParameters)
    }

    private func logSendWithSwapFinishScreenOpened() {
        Task {
            var analyticsParameters: [Analytics.ParameterKey: String] = [:]

            if let selectedFee = sendFeeInput?.selectedFee {
                let parameter = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee.option)
                analyticsParameters[.feeType] = parameter.rawValue
            }

            if let source = sendSourceTokenInput?.sourceToken {
                analyticsParameters[.sendToken] = source.tokenItem.currencySymbol
                analyticsParameters[.sendBlockchain] = source.tokenItem.blockchain.displayName
            }

            if let receive = sendReceiveTokenInput?.receiveToken.receiveToken {
                analyticsParameters[.receiveToken] = receive.tokenItem.currencySymbol
                analyticsParameters[.receiveBlockchain] = receive.tokenItem.blockchain.displayName
            }

            if let provider = await sendSwapProvidersInput?.selectedExpressProvider {
                analyticsParameters[.provider] = provider.provider.name
            }

            Analytics.log(event: .sendSendWithSwapInProgressScreenOpened, params: analyticsParameters)
        }
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
    func logTransactionRejected(error: Error) {
        Analytics.log(event: .sendErrorTransactionRejected, params: [
            .token: tokenItem.currencySymbol,
            .errorCode: "\(error.universalErrorCode)",
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }

    func logTransactionSent(amount: SendAmount?, additionalField: SendDestinationAdditionalField?, fee: SendFee, signerType: String) {
        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: fee.option)

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

        Analytics.log(event: .transactionSent, params: [
            .source: sourceValue.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter.rawValue,
            .walletForm: signerType,
        ])

        switch amount?.type {
        case .none: break
        case .typical: Analytics.log(.sendSelectedCurrency, params: [.commonType: .token])
        case .alternative: Analytics.log(.sendSelectedCurrency, params: [.commonType: .selectedCurrencyApp])
        }
    }
}

// MARK: - SendAnalyticsLogger

extension CommonSendAnalyticsLogger: SendAnalyticsLogger {
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
