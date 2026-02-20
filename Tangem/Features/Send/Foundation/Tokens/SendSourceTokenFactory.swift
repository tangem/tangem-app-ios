//
//  SendSourceTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SendSourceTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    func makeSourceToken(flowActionType: SendFlowActionType) -> SendSourceToken {
        let tokenHeaderProvider: SendGenericTokenHeaderProvider = switch flowActionType {
        case .unstake:
            UnstakingTokenHeaderProvider()
        default:
            SendTokenHeaderProvider(userWalletInfo: userWalletInfo, account: walletModel.account, flowActionType: flowActionType)
        }

        let header = tokenHeaderProvider.makeSendTokenHeader()

        let tokenHeader = ExpressInteractorTokenHeaderProvider(
            userWalletInfo: userWalletInfo,
            account: walletModel.account
        ).makeHeader()

        let tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        let possibleToConvertToFiat = walletModel.fiatAvailableBalanceProvider.balanceType.value != .none

        let sendingRestrictionsProvider = CommonSendingRestrictionsProvider(walletModel: walletModel)
        let receivingRestrictionsProvider = CommonReceivingRestrictionsProvider(walletModel: walletModel)

        let tokenFeeProvidersManagerProvider = CommonTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .swap
        )

        let transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )

        let allowanceService = AllowanceServiceFactory(
            walletModel: walletModel,
            transactionDispatcherProvider: transactionDispatcherProvider
        ).makeAllowanceService()

        let balanceProvider = CommonExpressBalanceProvider(
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeProvider: walletModel
        )

        let analyticsLogger = CommonExpressInteractorAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeAnalyticsParameterBuilder: .init(isFixedFee: !walletModel.shouldShowFeeSelector)
        )

        return CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: walletModel.id,
            header: header,
            tokenHeader: tokenHeader,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            isExemptFee: false,
            tokenIconInfo: tokenIconInfo,
            fiatItem: fiatItem,
            isCustom: walletModel.isCustom,
            possibleToConvertToFiat: possibleToConvertToFiat,
            availableBalanceProvider: walletModel.availableBalanceProvider,
            fiatAvailableBalanceProvider: walletModel.fiatAvailableBalanceProvider,
            allowanceService: allowanceService,
            defaultAddressString: walletModel.defaultAddressString,
            transactionValidator: walletModel.transactionValidator,
            transactionCreator: walletModel.transactionCreator,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider,
            tokenFeeProvidersManager: tokenFeeProvidersManagerProvider.makeTokenFeeProvidersManager(),
            sendingRestrictionsProvider: sendingRestrictionsProvider,
            receivingRestrictionsProvider: receivingRestrictionsProvider,
            tokenFeeProvidersManagerProvider: tokenFeeProvidersManagerProvider,
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: walletModel.account,
            balanceProvider: balanceProvider,
            analyticsLogger: analyticsLogger,
            operationType: .swap,
            supportedProvidersFilter: .swap
        )
    }
}
