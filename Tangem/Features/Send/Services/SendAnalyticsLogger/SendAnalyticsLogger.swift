//
//  SendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking
import TangemExpress

protocol SendAnalyticsLogger: SendManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendDestinationAnalyticsLogger,
    SendFeeAnalyticsLogger,
    FeeSelectorContentViewModelAnalytics,
    SendSwapProvidersAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger {
    func setup(sendFeeInput: SendFeeInput)
    func setup(sendSourceTokenInput: SendSourceTokenInput)
}

protocol StakingSendAnalyticsLogger: StakingAnalyticsLogger,
    SendManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendValidatorsAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger {
    func setup(stakingValidatorsInput: StakingValidatorsInput)
}

protocol OnrampSendAnalyticsLogger: SendBaseViewAnalyticsLogger,
    SendOnrampProvidersAnalyticsLogger,
    SendOnrampPaymentMethodAnalyticsLogger,
    SendFinishAnalyticsLogger {
    func setup(onrampProvidersInput: OnrampProvidersInput)

    func logOnrampSelectedProvider(provider: OnrampProvider)
}

// MARK: - ManagementModel

protocol SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: Error)
    func logTransactionSent(amount: SendAmount?, additionalField: SendDestinationAdditionalField?, fee: SendFee, signerType: String)
}

extension SendManagementModelAnalyticsLogger {
    func logTransactionSent(amount: SendAmount?, fee: SendFee, signerType: String) {
        logTransactionSent(amount: amount, additionalField: .none, fee: fee, signerType: signerType)
    }

    func logTransactionSent(fee: SendFee, signerType: String) {
        logTransactionSent(amount: .none, additionalField: .none, fee: fee, signerType: signerType)
    }
}

// MARK: - SendBaseView

protocol SendBaseViewAnalyticsLogger {
    func logSendBaseViewOpened()

    func logShareButton()
    func logExploreButton()
    func logRequestSupport()

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType)
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool)
}

// MARK: - SendSteps

protocol SendDestinationAnalyticsLogger {
    func logSendAddressEntered(isAddressValid: Bool, source: Analytics.DestinationAddressSource)
    func logQRScannerOpened()

    func logDestinationStepOpened()
    func logDestinationStepReopened()
}

protocol SendAmountAnalyticsLogger {
    func logTapMaxAmount()

    func logAmountStepOpened()
    func logAmountStepReopened()
}

protocol SendFeeAnalyticsLogger {
    func logSendFeeSelected(_ feeOption: FeeOption)

    func logSendNoticeTransactionDelaysArePossible()
    func logFeeStepOpened()
    func logFeeStepReopened()
}

protocol SendValidatorsAnalyticsLogger {
    func logStakingValidatorChosen()
}

protocol SendOnrampProvidersAnalyticsLogger {
    func logOnrampProvidersScreenOpened()
    func logOnrampProviderChosen(provider: ExpressProvider)
}

protocol SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampPaymentMethodScreenOpened()
    func logOnrampPaymentMethodChosen(paymentMethod: OnrampPaymentMethod)
}

protocol SendSwapProvidersAnalyticsLogger {
    func logSendSwapProvidersChosen(provider: ExpressProvider)
}

protocol SendSummaryAnalyticsLogger {
    func logUserDidTapOnValidator()

    func logSummaryStepOpened()
}

protocol SendFinishAnalyticsLogger {
    func logFinishStepOpened()
}
