//
//  SendModulesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendModulesFactory {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let builder: SendModulesStepsBuilder

    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel

        builder = .init(userWalletName: userWalletModel.name, walletModel: walletModel)
    }

    // MARK: - Modules

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let sendModel = makeSendModel(type: type)
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
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
            processor: makeDestinationViewModelProcessor(),
            coordinator: coordinator
        )
    }

    func makeSendDestinationViewModel(
        input: DestinationViewModelInput,
        output: DestinationViewModelOutput,
        sendType: SendType,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let additionalFieldType = SendAdditionalFields.fields(for: tokenItem.blockchain)
        let initial = SendDestinationViewModel.InitialModel(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets,
            transactionHistoryPublisher: walletModel.transactionHistoryPublisher,
            predefinedDestination: sendType.predefinedDestination,
            predefinedTag: sendType.predefinedTag
        )

        let transactionHistoryMapper = TransactionHistoryMapper(
            currencySymbol: tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )

        return SendDestinationViewModel(
            initial: initial,
            input: input,
            output: output,
            processor: makeDestinationViewModelProcessor(),
            addressTextViewHeightModel: addressTextViewHeightModel,
            transactionHistoryMapper: transactionHistoryMapper
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
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
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
        SendFinishViewModel(
            input: sendModel,
            fiatCryptoValueProvider: fiatCryptoAdapter,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: feeTypeAnalyticsParameter,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    // MARK: - Dependencies

    private var emailDataProvider: EmailDataProvider { 
        userWalletModel
    }
    
    private var transactionSigner: TransactionSigner {
        userWalletModel.signer
    }

    private func makeSendModel(type: SendType) -> SendModel {
        SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
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

    private func makeSendSummarySectionViewModelFactory(walletInfo: SendWalletInfo) -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )
    }

    func makeDestinationViewModelProcessor() -> DestinationViewModelProcessor {
        let parametersBuilder = SendTransactionParametersBuilder(blockchain: tokenItem.blockchain)

        return CommonDestinationViewModelProcessor(
            validator: makeDestinationViewModelValidator(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .fields(for: tokenItem.blockchain),
            parametersBuilder: parametersBuilder
        )
    }

    func makeDestinationViewModelValidator() -> DestinationViewModelValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let validator = CommonDestinationViewModelValidator(
            walletAddresses: walletModel.addresses,
            addressService: addressService,
            supportsCompound: walletModel.wallet.blockchain.supportsCompound
        )

        return validator
    }
}

private extension Blockchain {
    var supportsCompound: Bool {
        switch self {
        case .bitcoin,
             .bitcoinCash,
             .litecoin,
             .dogecoin,
             .dash,
             .kaspa,
             .ravencoin,
             .ducatus:
            return true
        default:
            return false
        }
    }
}
