//
//  CommonSendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

class CommonSendAnalyticsLogger {
    private weak var sendFeeInput: SendFeeInput?
    private weak var sendSourceTokenInput: SendSourceTokenInput?

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private let coordinatorSource: SendCoordinator.Source

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        coordinatorSource: SendCoordinator.Source
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.coordinatorSource = coordinatorSource
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
        case .nonFungible:
            Analytics.log(.nftCommissionScreenOpened)
        case .fungible, .none:
            Analytics.log(.sendFeeScreenOpened)
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
        Analytics.log(.sendMaxAmountTapped)
    }

    func logAmountStepOpened() {
        Analytics.log(.sendAmountScreenOpened)
    }

    func logAmountStepReopened() {
        Analytics.log(.sendScreenReopened, params: [.source: .amount])
    }
}

// MARK: - SendAmountAnalyticsLogger

extension CommonSendAnalyticsLogger: SendSwapProvidersAnalyticsLogger {
    func logSendSwapProvidersChosen(provider: ExpressProvider) {
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.name])
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
}

// MARK: - SendFinishAnalyticsLogger

extension CommonSendAnalyticsLogger: SendFinishAnalyticsLogger {
    func logFinishStepOpened() {
        let feeTypeAnalyticsParameter = feeAnalyticsParameterBuilder.analyticsParameter(
            selectedFee: sendFeeInput?.selectedFee.option
        )

        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSentScreenOpened
        default: .sendTransactionSentScreenOpened
        }

        Analytics.log(event: event, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])
    }
}

// MARK: - SendBaseViewAnalyticsLogger

extension CommonSendAnalyticsLogger: SendBaseViewAnalyticsLogger {
    func logShareButton() {
        Analytics.log(.sendButtonShare)
    }

    func logExploreButton() {
        Analytics.log(.sendButtonExplore)
    }

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

        Analytics.log(event: .transactionSent, params: [
            .source: coordinatorSource.analytics.rawValue,
            .token: tokenItem.currencySymbol,
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
}
