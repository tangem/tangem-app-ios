//
//  TransactionBuildingFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TransactionBuildingFactory {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    // MARK: - Modules

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let sendModel = makeSendModel(type: type)
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
        let builder = TransactionBuildingStepsBuilder(userWalletName: userWalletModel.name, walletModel: walletModel)
        let walletInfo = builder.makeSendWalletInfo(canUseFiatCalculation: canUseFiatCalculation)

        return SendViewModel(
            walletInfo: walletInfo,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: transactionSigner,
            sendType: type,
            emailDataProvider: emailDataProvider,
            sendModel: sendModel,
            notificationManager: makeSendNotificationManager(sendModel: sendModel),
            customFeeService: makeCustomFeeService(sendModel: sendModel),
            fiatCryptoAdapter: makeSendFiatCryptoAdapter(walletInfo: walletInfo),
            keyboardVisibilityService: KeyboardVisibilityService(),
            factory: self,
            coordinator: coordinator
        )
    }

    func makeSendDestinationViewModel(
        sendModel: SendModel,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        SendDestinationViewModel(
            input: sendModel,
            addressTextViewHeightModel: addressTextViewHeightModel
        )
    }

    func makeSendAmountViewModel(
        sendModel: SendModel,
        fiatCryptoAdapter: CommonSendFiatCryptoAdapter,
        walletInfo: SendWalletInfo
    ) -> SendAmountViewModel {
        SendAmountViewModel(
            input: sendModel,
            fiatCryptoAdapter: fiatCryptoAdapter,
            walletInfo: walletInfo
        )
    }

    func makeSendFeeViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        customFeeService: CustomFeeService?,
        walletInfo: SendWalletInfo
    ) -> SendFeeViewModel {
        SendFeeViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            customFeeService: customFeeService,
            walletInfo: walletInfo
        )
    }

    func makeSendSummaryViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        fiatCryptoAdapter: CommonSendFiatCryptoAdapter,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo
    ) -> SendSummaryViewModel {
        SendSummaryViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            fiatCryptoValueProvider: fiatCryptoAdapter,
            addressTextViewHeightModel: addressTextViewHeightModel,
            walletInfo: walletInfo
        )
    }

    func makeSendFinishViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        fiatCryptoAdapter: CommonSendFiatCryptoAdapter,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo
    ) -> SendFinishViewModel? {
        return SendFinishViewModel(
            input: sendModel,
            fiatCryptoValueProvider: fiatCryptoAdapter,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: feeTypeAnalyticsParameter,
            walletInfo: walletInfo
        )
    }

    // MARK: - Dependencies

    private var emailDataProvider: EmailDataProvider { userWalletModel }
    private var transactionSigner: TransactionSigner { userWalletModel.signer }

    private var sendAddressService: SendAddressService {
        SendAddressServiceFactory(walletModel: walletModel).makeService()
    }

    private func makeSendModel(type: SendType) -> SendModel {
        SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            addressService: sendAddressService,
            sendType: type
        )
    }

    private func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )
    }

    private func makeCustomFeeService(sendModel: SendModel) -> CustomFeeService? {
        CustomFeeServiceFactory(input: sendModel, output: sendModel, walletModel: walletModel).makeService()
    }

    private func makeSendFiatCryptoAdapter(walletInfo: SendWalletInfo) -> CommonSendFiatCryptoAdapter {
        CommonSendFiatCryptoAdapter(
            cryptoCurrencyId: walletInfo.currencyId,
            currencySymbol: walletInfo.cryptoCurrencyCode,
            decimals: walletInfo.amountFractionDigits
        )
    }
}
