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

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel

        builder = .init(userWalletName: userWalletModel.name, walletModel: walletModel)
    }

    // MARK: - ViewModels

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let tokenItem = walletModel.tokenItem
        let sendModel = makeSendModel(type: type)
        let canUseFiatCalculation = quotesRepository.quote(for: tokenItem) != nil
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
            keyboardVisibilityService: KeyboardVisibilityService(),
            sendAmountValidator: makeSendAmountValidator(),
            factory: self,
            coordinator: coordinator
        )
    }

    func makeSendDestinationViewModel(
        input: SendDestinationInput,
        output: SendDestinationOutput,
        sendType: SendType,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let additionalFieldType = SendAdditionalFields.fields(for: tokenItem.blockchain)
        let settings = SendDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let interactor = makeSendDestinationInteractor(input: input, output: output)

        let viewModel = SendDestinationViewModel(
            settings: settings,
            interactor: interactor,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let address = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
        viewModel.setExternally(address: address, additionalField: sendType.predefinedTag)

        return viewModel
    }

    func makeSendAmountViewModel(
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator,
        sendType: SendType
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData(),
            predefinedAmount: sendType.predefinedAmount?.value
        )

        let interactor = makeSendAmountInteractor(input: input, output: output, validator: validator)

        return SendAmountViewModel(initial: initital, interactor: interactor)
    }

    func makeSendFeeViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        customFeeService: CustomFeeService?,
        walletInfo: SendWalletInfo
    ) -> SendFeeViewModel {
        return SendFeeViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            customFeeService: customFeeService,
            walletInfo: walletInfo
        )
    }

    func makeSendSummaryViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo
    ) -> SendSummaryViewModel {
        let initial = SendSummaryViewModel.Initial(tokenItem: walletModel.tokenItem)

        return SendSummaryViewModel(
            initial: initial,
            input: sendModel,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    func makeSendFinishViewModel(
        amount: SendAmount?,
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo
    ) -> SendFinishViewModel? {
        let initial = SendFinishViewModel.Initial(tokenItem: walletModel.tokenItem, amount: amount)

        return SendFinishViewModel(
            initial: initial,
            input: sendModel,
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
        return userWalletModel.signer
    }

    private func makeSendModel(type: SendType) -> SendModel {
        return SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            sendType: type
        )
    }

    private func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        return CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )
    }

    private func makeCustomFeeService(sendModel: SendModel) -> CustomFeeService? {
        return CustomFeeServiceFactory(input: sendModel, output: sendModel, walletModel: walletModel).makeService()
    }

    private func makeSendSummarySectionViewModelFactory(walletInfo: SendWalletInfo) -> SendSummarySectionViewModelFactory {
        return SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )
    }

    private func makeSendDestinationInteractor(
        input: SendDestinationInput,
        output: SendDestinationOutput
    ) -> SendDestinationInteractor {
        let parametersBuilder = SendTransactionParametersBuilder(blockchain: walletModel.tokenItem.blockchain)

        return CommonSendDestinationInteractor(
            input: input,
            output: output,
            validator: makeSendDestinationValidator(),
            transactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
            transactionHistoryMapper: makeTransactionHistoryMapper(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .fields(for: walletModel.tokenItem.blockchain),
            parametersBuilder: parametersBuilder
        )
    }

    private func makeSendDestinationValidator() -> SendDestinationValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let validator = CommonSendDestinationValidator(
            walletAddresses: walletModel.addresses,
            addressService: addressService,
            supportsCompound: walletModel.wallet.blockchain.supportsCompound
        )

        return validator
    }

    private func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(walletModel: walletModel)
    }

    private func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )
    }

    private func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    private func makeSendAmountInteractor(
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            input: input,
            output: output,
            validator: validator,
            type: .crypto
        )
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
