//
//  SendModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.06.2024.
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

    func makeSendViewModel(sendType: SendType, router: SendRoutable) -> SendViewModel {
        let sendAmountInteractor = makeSendAmountInteractor()
        let sendFeeInteractor = makeSendFeeInteractor()
        let informationRelevanceService = makeInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
        let sendTransactionSender = makeSendTransactionSender()

        let sendModel = makeSendModel(
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            informationRelevanceService: informationRelevanceService,
            sendTransactionSender: sendTransactionSender,
            type: type
        )

        let notificationManager = makeSendNotificationManager(sendModel: sendModel)

        sendAmountInteractor.setup(input: sendModel, output: sendModel)
        sendFeeInteractor.setup(input: sendModel, output: sendModel)

        let destinationStep = makeSendDestinationStep(
            input: sendModel,
            output: sendModel,
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            router: router
        )

        let amountStep = makeSendAmountStep(sendAmountInteractor: sendAmountInteractor, sendFeeInteractor: sendFeeInteractor)
        let feeStep = makeFeeSendStep(sendFeeInteractor: sendFeeInteractor, notificationManager: notificationManager, router: router)
        let summaryStep = makeSendSummaryStep(
            input: sendModel,
            output: sendModel,
            sendTransactionSender: sendTransactionSender,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        summaryStep.viewModel.setup(sendDestinationInput: sendModel)
        summaryStep.viewModel.setup(sendAmountInput: sendModel)
        summaryStep.viewModel.setup(sendFeeInteractor: sendFeeInteractor)

        let finishStep = makeSendFinishStep(
            sendModel: sendModel,
            sendFeeInteractor: sendFeeInteractor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let stepsManager = CommonSendStepsManager(
            destinationStep: destinationStep,
            amountStep: amountStep,
            feeStep: feeStep,
            summaryStep: summaryStep,
            finishStep: finishStep
        )

        let sendBaseInteractor = CommonSendBaseInteractor(input: sendModel, output: sendModel, sendDestinationInput: sendModel)
        let viewModel = SendViewModel(
            interactor: sendBaseInteractor,
            stepsManager: stepsManager,
            router: router
        )
        sendModel.delegate = viewModel
        return viewModel
    }

    /*
     func makeStepManager(sendType: SendType, router: SendRoutable) -> SendStepsManager {
         let sendAmountInteractor = makeSendAmountInteractor()
         let sendFeeInteractor = makeSendFeeInteractor()
         let informationRelevanceService = makeInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
         let addressTextViewHeightModel: AddressTextViewHeightModel = .init()

         let sendModel = makeSendModel(
             sendAmountInteractor: sendAmountInteractor,
             sendFeeInteractor: sendFeeInteractor,
             informationRelevanceService: informationRelevanceService,
             type: sendType,
             router: router
         )

         let notificationManager = makeSendNotificationManager(sendModel: sendModel)

         sendAmountInteractor.setup(input: sendModel, output: sendModel)
         sendFeeInteractor.setup(input: sendModel, output: sendModel)

         let destinationStep = makeSendDestinationStep(
             input: sendModel,
             output: sendModel,
             sendFeeInteractor: sendFeeInteractor,
             addressTextViewHeightModel: addressTextViewHeightModel
         )

         let amountStep = makeSendAmountStep(sendAmountInteractor: sendAmountInteractor, sendFeeInteractor: sendFeeInteractor)
         let feeStep = makeFeeSendStep(sendFeeInteractor: sendFeeInteractor, notificationManager: notificationManager, router: router)
         let summaryStep = makeSendSummaryStep(
             interactor: sendModel,
             notificationManager: notificationManager,
             addressTextViewHeightModel: addressTextViewHeightModel,
             sendType: sendType
         )

         summaryStep.viewModel.setup(sendDestinationInput: sendModel)
         summaryStep.viewModel.setup(sendAmountInput: sendModel)
         summaryStep.viewModel.setup(sendFeeInteractor: sendFeeInteractor)

         let finishStep = makeSendFinishStep(
             sendModel: sendModel,
             notificationManager: notificationManager,
             addressTextViewHeightModel: addressTextViewHeightModel
         )

         return CommonSendStepsManager(
             destinationStep: destinationStep,
             amountStep: amountStep,
             feeStep: feeStep,
             summaryStep: summaryStep,
             finishStep: finishStep
         )
     }
     */

    // MARK: - DestinationStep

    func makeSendDestinationStep(
        input: any SendDestinationInput,
        output: any SendDestinationOutput,
        sendAmountInteractor: any SendAmountInteractor,
        sendFeeInteractor: any SendFeeInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        router: SendDestinationRoutable
    ) -> SendDestinationStep {
        let sendDestinationInteractor = makeSendDestinationInteractor(input: input, output: output)

        let viewModel = makeSendDestinationViewModel(
            input: input,
            output: output,
//            sendType: <#T##SendType#>,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        return SendDestinationStep(
            viewModel: viewModel,
            interactor: sendDestinationInteractor,
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            tokenItem: walletModel.tokenItem,
            router: router
        )
    }

    func makeSendDestinationViewModel(
        input: SendDestinationInput,
        output: SendDestinationOutput,
//        sendType: SendType,
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

//        let address = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
//        viewModel.setExternally(address: address, additionalField: sendType.predefinedTag)

        return viewModel
    }

    // MARK: - AmountStep

    func makeSendAmountStep(
        sendAmountInteractor: any SendAmountInteractor,
        sendFeeInteractor: any SendFeeInteractor
    ) -> SendAmountStep {
        let viewModel = makeSendAmountViewModel(
            interactor: sendAmountInteractor,
            predefinedAmount: nil
        )

        return SendAmountStep(
            viewModel: viewModel,
            interactor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor
        )
    }

    func makeSendAmountViewModel(
        interactor: SendAmountInteractor,
        predefinedAmount: Decimal?
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData(),
            predefinedAmount: predefinedAmount
        )

        return SendAmountViewModel(initial: initital, interactor: interactor)
    }

    // MARK: - FeeStep

    func makeFeeSendStep(
        sendFeeInteractor: any SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) -> SendFeeStep {
        let viewModel = makeSendFeeViewModel(
            sendFeeInteractor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router
        )

        return SendFeeStep(
            viewModel: viewModel,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            tokenItem: walletModel.tokenItem,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder()
        )
    }

    func makeSendFeeViewModel(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) -> SendFeeViewModel {
        let settings = SendFeeViewModel.Settings(tokenItem: walletModel.tokenItem)

        return SendFeeViewModel(
            settings: settings,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router
        )
    }

    // MARK: - SummaryStep

    func makeSendSummaryStep(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendTransactionSender: any SendTransactionSender,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sendType: SendType
    ) -> SendSummaryStep {
        let interactor = CommonSendSummaryInteractor(
            input: input,
            output: output,
            sendTransactionSender: sendTransactionSender,
            descriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        return SendSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            tokenItem: walletModel.tokenItem,
            walletName: userWalletModel.name
        )
    }

    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        editableType: SendSummaryViewModel.EditableType
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            editableType: editableType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
        )
    }

    func makeSendSummaryInteractor(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendTransactionSender: any SendTransactionSender
    ) -> SendSummaryInteractor {
        CommonSendSummaryInteractor(
            input: input,
            output: output,
            sendTransactionSender: sendTransactionSender,
            descriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - Dependencies

private extension SendModulesFactory {
    var emailDataProvider: EmailDataProvider {
        return userWalletModel
    }

    var transactionSigner: TransactionSigner {
        return userWalletModel.signer
    }

    private func makeSendModel(
        sendAmountInteractor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor,
        informationRelevanceService: InformationRelevanceService,
        sendTransactionSender: any SendTransactionSender,
        type: SendType,
        router: SendRoutable
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendTransactionSender: sendTransactionSender,
            transactionCreator: walletModel.transactionCreator,
            transactionSigner: transactionSigner,
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            feeIncludedCalculator: feeIncludedCalculator,
            informationRelevanceService: informationRelevanceService,
            emailDataProvider: emailDataProvider,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            sendType: type,
            coordinator: router
        )
    }

    private func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        let manager = CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )

        manager.setupManager(with: sendModel)

        return manager
    }

    func makeSendSummarySectionViewModelFactory() -> SendSummarySectionViewModelFactory {
        return SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: builder.isFeeApproximate(),
            currencyId: walletModel.tokenItem.currencyId,
            tokenIconInfo: builder.makeTokenIconInfo()
        )
    }

    func makeSendDestinationInteractor(
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

    func makeSendDestinationValidator() -> SendDestinationValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let validator = CommonSendDestinationValidator(
            walletAddresses: walletModel.addresses,
            addressService: addressService,
            supportsCompound: walletModel.wallet.blockchain.supportsCompound
        )

        return validator
    }

    func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(walletModel: walletModel)
    }

    func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )
    }

    func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    private func makeSendAmountInteractor() -> SendAmountInteractor {
        CommonSendAmountInteractor(
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            validator: makeSendAmountValidator(),
            type: .crypto
        )
    }

    private func makeSendFeeInteractor() -> SendFeeInteractor { // predefinedAmount: Amount?, predefinedDestination: String?
        let customFeeService = CustomFeeServiceFactory(walletModel: walletModel).makeService()
        let interactor = CommonSendFeeInteractor(
            provider: makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
//            predefinedAmount: predefinedAmount,
//            predefinedDestination: predefinedDestination
        )

        customFeeService?.setup(input: interactor, output: interactor)
        return interactor
    }

    func makeSendFeeProvider() -> SendFeeProvider {
        CommonSendFeeProvider(walletModel: walletModel)
    }

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
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

    private func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: builder.makeFeeOptions().count == 1)
    }

    private func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        SendTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeSendTransactionSender() -> SendTransactionSender {
        CommonSendTransactionSender(
            walletModel: walletModel,
            transactionSigner: transactionSigner
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
