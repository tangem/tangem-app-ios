//
//  SendAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking
import TangemExpress
import BlockchainSdk

protocol SendAnalyticsLogger: SendManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendReceiveTokensListAnalyticsLogger,
    SendDestinationAnalyticsLogger,
    SendFeeAnalyticsLogger,
    FeeSelectorAnalytics,
    SendSwapProvidersAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendApproveAnalyticsLogger,
    SwapManagementModelAnalyticsLogger {
    func setup(sendDestinationInput: any SendDestinationInput)
    func setup(sendFeeInput: any SendFeeInput)
    func setup(sendSourceTokenInput: any SendSourceTokenInput)
    func setup(sendReceiveTokenInput: any SendReceiveTokenInput)
    func setup(sendSwapProvidersInput: any SendSwapProvidersInput)
}

protocol StakingSendAnalyticsLogger: StakingAnalyticsLogger,
    SendManagementModelAnalyticsLogger,
    SendBaseViewAnalyticsLogger,
    SendAmountAnalyticsLogger,
    SendTargetsAnalyticsLogger,
    SendSummaryAnalyticsLogger,
    SendFinishAnalyticsLogger,
    SendApproveAnalyticsLogger {
    func setup(stakingTargetsInput: StakingTargetsInput)
    func logNoticeUninitializedAddress()
    func logNoticeNotEnoughFee()
}

protocol OnrampSendAnalyticsLogger: SendBaseViewAnalyticsLogger,
    SendOnrampOffersAnalyticsLogger,
    SendOnrampProvidersAnalyticsLogger,
    SendOnrampPaymentMethodAnalyticsLogger,
    SendOnrampNAPAnalyticsLogger,
    SendFinishAnalyticsLogger {
    func setup(onrampProvidersInput: OnrampProvidersInput)

    func logOnrampSelectedProvider(provider: OnrampProvider)
}

// MARK: - ManagementModel

protocol SendManagementModelAnalyticsLogger {
    func logTransactionRejected(error: SendTxError)
    func logTransactionSent(
        amount: SendAmount?,
        additionalField: SendDestinationAdditionalField?,
        fee: FeeOption,
        signerType: String,
        currentProviderHost: String,
        tokenFee: TokenFee?
    )
}

extension SendManagementModelAnalyticsLogger {
    func logTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String) {
        logTransactionSent(
            amount: amount,
            additionalField: .none,
            fee: fee,
            signerType: signerType,
            currentProviderHost: currentProviderHost,
            tokenFee: nil
        )
    }

    func logTransactionSent(fee: FeeOption, signerType: String, currentProviderHost: String) {
        logTransactionSent(
            amount: .none,
            additionalField: .none,
            fee: fee,
            signerType: signerType,
            currentProviderHost: currentProviderHost,
            tokenFee: nil
        )
    }
}

// MARK: - SendApproveAnalyticsLogger

protocol SendApproveAnalyticsLogger {
    func logPermissionScreenOpened(isRevoke: Bool)
    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy)
    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String)
}

// MARK: - SendSwapAnalyticsLogger

protocol SwapManagementModelAnalyticsLogger {
    func logSwapButtonSwap()
    func logSwapButtonTransfer()
    func logSwapTransferModeSwitched()
    func logSwapTransactionSent(result: TransactionDispatcherResult)
    func logSwapPreselectedTokenChanged(
        direction: Analytics.ParameterValue,
        preselectedSymbol: String,
        selectedSymbol: String
    )
}

// MARK: - SendBaseView

protocol SendBaseViewAnalyticsLogger {
    func logSendBaseViewOpened()

    func logRequestSupport()

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType)
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool)
}

// MARK: - SendSteps

protocol SendDestinationAnalyticsLogger {
    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource)
    func logQRScannerOpened()

    func logDestinationStepOpened()
    func logDestinationStepReopened()

    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?)
}

protocol SendAmountAnalyticsLogger {
    func logTapMaxAmount()
    func logTapConvertToAnotherToken()

    func logAmountStepOpened()
    func logAmountStepReopened()

    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue)
    func logSwapErrorMinAmount(screen: Analytics.ParameterValue)
    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue)
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String)
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?)
}

extension SendAmountAnalyticsLogger {
    func logSwapErrorInsufficientBalance(screen: Analytics.ParameterValue) {}
    func logSwapErrorMinAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorMaxAmount(screen: Analytics.ParameterValue) {}
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {}
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {}
}

protocol SendReceiveTokensListAnalyticsLogger {
    func logSearchClicked()
    func logTokenSearched(coin: CoinModel, searchText: String?)

    func logTokenChosen(token: TokenItem)
    func logSendSwapCantSwapThisToken(token: String)
}

protocol SendFeeAnalyticsLogger {
    func logFeeSelected(tokenFee: TokenFee)
    func logFeeSelected(_ feeOption: FeeOption)

    func logSendNoticeTransactionDelaysArePossible()
    func logFeeStepOpened()
    func logFeeStepReopened()
    func logFeeSummaryOpened()
    func logFeeTokensOpened(availableTokenFees: [TokenFee])
}

protocol SendTargetsAnalyticsLogger {
    func logStakingTargetChosen()
}

protocol SendOnrampOffersAnalyticsLogger: SendOnrampProvidersAnalyticsLogger,
    SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampOfferButtonBuy(provider: OnrampProvider)
    func logOnrampRecentlyUsedClicked(provider: OnrampProvider)
    func logOnrampFastestMethodClicked(provider: OnrampProvider)
    func logOnrampBestRateClicked(provider: OnrampProvider)

    func logOnrampButtonAllOffers()
}

protocol SendOnrampProvidersAnalyticsLogger {
    func logOnrampProvidersScreenOpened()
    func logOnrampProviderChosen(provider: ExpressProvider)
}

protocol SendOnrampPaymentMethodAnalyticsLogger {
    func logOnrampPaymentMethodScreenOpened()
    func logOnrampPaymentMethodChosen(paymentMethod: OnrampPaymentMethod)
}

protocol SendOnrampNAPAnalyticsLogger {
    func logOnrampButtonNAP(amount: Decimal, currencyCode: String)
    func logOnrampNAPScreenOpened()
    func logOnrampVerifyScreenOpened(amount: Decimal, currencyCode: String)
}

protocol SendSwapProvidersAnalyticsLogger {
    func logSendSwapProvidersChosen(provider: ExpressProvider)
}

protocol SendSummaryAnalyticsLogger {
    func logUserDidTapOnValidator()
    func logUserDidTapOnProvider()

    func logSummaryStepOpened()

    func logTapAmountFraction(_ fraction: SwapAmountFraction)

    func logSwapTypeReselection(from: SwapFormVariant, to: SwapFormVariant)
    func logSwapTypeScreenOpened(variant: SwapFormVariant)
}

extension SendSummaryAnalyticsLogger {
    func logTapAmountFraction(_ fraction: SwapAmountFraction) {}

    func logSwapTypeReselection(from: SwapFormVariant, to: SwapFormVariant) {}
    func logSwapTypeScreenOpened(variant: SwapFormVariant) {}
}

protocol SendFinishAnalyticsLogger {
    func logFinishStepOpened()

    func logShareButton()
    func logExploreButton()
}
