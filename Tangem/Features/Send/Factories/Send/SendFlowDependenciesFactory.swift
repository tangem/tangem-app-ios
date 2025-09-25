//
//  SendFlowDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

struct SendFlowDependenciesFactory {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let userWalletInfo: SendWalletInfo
    let walletAddresses: [String]
    let suggestedWallets: [SendDestinationSuggestedWallet]

    let shouldShowFeeSelector: Bool

    let sendBaseDataBuilderFactory: SendBaseDataBuilderFactory

    let walletModelHistoryUpdater: any WalletModelHistoryUpdater
    let walletModelFeeProvider: any WalletModelFeeProvider
    let walletModelDependenciesProvider: WalletModelDependenciesProvider
    let walletModelBalancesProvider: WalletModelBalancesProvider
    let transactionDispatcherFactory: TransactionDispatcherFactory
    let expressDependenciesFactory: ExpressDependenciesFactory

    // MARK: - Analytics

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            sendType: sendType
        )
    }

    func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: makeFeeOptions().count == 1)
    }

    func makeFeeOptions() -> [FeeOption] {
        if shouldShowFeeSelector {
            return [.slow, .market, .fast]
        }

        return [.market]
    }

    // MARK: - Destination

    func makeSendQRCodeService() -> SendQRCodeService {
        CommonSendQRCodeService(
            parser: QRCodeParser(
                amountType: tokenItem.amountType,
                blockchain: tokenItem.blockchain,
                decimalCount: tokenItem.decimalCount
            )
        )
    }

    func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(
            transactionHistoryUpdater: walletModelHistoryUpdater,
            transactionHistoryMapper: makeTransactionHistoryMapper()
        )
    }

    func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: tokenItem.currencySymbol,
            walletAddresses: walletAddresses,
            showSign: false
        )
    }

    func makeSendDestinationInteractorDependenciesProvider(analyticsLogger: any SendDestinationAnalyticsLogger) -> SendDestinationInteractorDependenciesProvider {
        SendDestinationInteractorDependenciesProvider(
            receivedTokenType: .same(makeSourceToken()),
            sendingWalletData: .init(
                walletAddresses: walletAddresses,
                suggestedWallets: suggestedWallets,
                destinationTransactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
                analyticsLogger: analyticsLogger
            )
        )
    }

    // MARK: - Amount

    func possibleToChangeAmountType() -> Bool {
        walletModelBalancesProvider.fiatAvailableBalanceProvider.balanceType.value != .none
    }

    func makeSendSourceTokenAmountValidator(input: any SendSourceTokenInput) -> SendAmountValidator {
        CommonSendAmountValidator(input: input)
    }

    // MARK: - Fee

    func makeSendWithSwapFeeProvider(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeProvider: SendFeeProvider,
        swapFeeProvider: SendFeeProvider
    ) -> SendFeeProvider {
        SendWithSwapFeeProvider(
            receiveTokenInput: receiveTokenInput,
            sendFeeProvider: sendFeeProvider,
            swapFeeProvider: swapFeeProvider
        )
    }

    func makeSendFeeProvider(input: any SendFeeProviderInput) -> SendFeeProvider {
        var options = makeFeeOptions()

        if makeCustomFeeService(input: input) != nil {
            options.append(.custom)
        }

        return CommonSendFeeProvider(
            input: input,
            feeLoader: makeSendFeeLoader(),
            defaultFeeOptions: options
        )
    }

    func makeSwapFeeProvider(swapManager: SwapManager) -> SendFeeProvider {
        SwapFeeProvider(swapManager: swapManager)
    }

    func makeSendFeeLoader() -> SendFeeLoader {
        CommonSendFeeLoader(
            tokenItem: tokenItem,
            walletModelFeeProvider: walletModelFeeProvider
        )
    }

    func makeCustomFeeService(input: any CustomFeeServiceInput) -> CustomFeeService? {
        CustomFeeServiceFactory(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            bitcoinTransactionFeeCalculator: walletModelDependenciesProvider.bitcoinTransactionFeeCalculator
        ).makeService(input: input)
    }

    func isFeeApproximate() -> Bool {
        tokenItem.blockchain.isFeeApproximate(for: tokenItem.amountType)
    }

    // MARK: - Management Model

    func makeSendWithSwapModel(
        swapManager: SwapManager,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: SendModel.PredefinedValues = .init()
    ) -> SendModel {
        SendModel(
            userToken: makeSourceToken(),
            transactionSigner: userWalletInfo.signer,
            feeIncludedCalculator: makeFeeIncludedCalculator(),
            analyticsLogger: analyticsLogger,
            sendReceiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            swapManager: swapManager,
            predefinedValues: predefinedValues
        )
    }

    func makeSwapManager() -> SwapManager {
        CommonSwapManager(interactor: expressDependenciesFactory.expressInteractor)
    }

    func makeSourceToken() -> SendSourceToken {
        SendSourceToken(
            wallet: userWalletInfo.name,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            tokenIconInfo: tokenIconInfo,
            fiatItem: makeFiatItem(),
            possibleToConvertToFiat: possibleToChangeAmountType(),
            availableBalanceProvider: walletModelBalancesProvider.availableBalanceProvider,
            fiatAvailableBalanceProvider: walletModelBalancesProvider.fiatAvailableBalanceProvider,
            transactionValidator: walletModelDependenciesProvider.transactionValidator,
            transactionCreator: walletModelDependenciesProvider.transactionCreator,
            transactionDispatcher: makeTransactionDispatcher()
        )
    }

    func makeFiatItem() -> FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeTransactionDispatcher() -> TransactionDispatcher {
        transactionDispatcherFactory.makeSendDispatcher()
    }

    func makeFeeIncludedCalculator() -> FeeIncludedCalculator {
        CommonFeeIncludedCalculator(validator: walletModelDependenciesProvider.transactionValidator)
    }

    func makeInformationRelevanceService(input: SendFeeInput, output: SendFeeOutput, provider: SendFeeProvider) -> InformationRelevanceService {
        CommonInformationRelevanceService(input: input, output: output, provider: provider)
    }

    // MARK: - Summary

    func makeSendWithSwapSummaryTitleProvider(receiveTokenInput: SendReceiveTokenInput) -> SendSummaryTitleProvider {
        SendWithSwapSummaryTitleProvider(receiveTokenInput: receiveTokenInput)
    }

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        if case .nonFungible = tokenItem.token?.metadata.kind {
            return NFTSendTransactionSummaryDescriptionBuilder(feeTokenItem: feeTokenItem)
        }

        switch tokenItem.blockchain {
        case .koinos:
            return KoinosSendTransactionSummaryDescriptionBuilder(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem
            )
        case .tron where tokenItem.isToken:
            return TronSendTransactionSummaryDescriptionBuilder(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem
            )
        default:
            return CommonSendTransactionSummaryDescriptionBuilder(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem
            )
        }
    }

    func makeSwapTransactionSummaryDescriptionBuilder() -> SwapTransactionSummaryDescriptionBuilder {
        CommonSwapTransactionSummaryDescriptionBuilder(
            sendTransactionSummaryDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )
    }

    // MARK: - Notifications

    func makeSendNewNotificationManager(receiveTokenInput: SendReceiveTokenInput?) -> SendNotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: makeSendNotificationManager(),
            expressNotificationManager: makeExpressNotificationManager()
        )
    }

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            withdrawalNotificationProvider: walletModelDependenciesProvider.withdrawalNotificationProvider
        )
    }

    func makeExpressNotificationManager() -> ExpressNotificationManager {
        ExpressNotificationManager(
            userWalletId: userWalletInfo.id,
            expressInteractor: expressDependenciesFactory.expressInteractor
        )
    }

    // MARK: - Base

    func makeSendBaseDataBuilder(
        input: SendBaseDataBuilderInput,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder
    ) -> SendBaseDataBuilder {
        sendBaseDataBuilderFactory.makeSendBaseDataBuilder(
            input: input,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )
    }

    func makeBlockchainSDKNotificationMapper() -> BlockchainSDKNotificationMapper {
        BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
    }

    // MARK: - Receive token

    func makeSendReceiveTokensListBuilder(
        sendSourceTokenInput: SendSourceTokenInput,
        receiveTokenOutput: SendReceiveTokenOutput,
        analyticsLogger: any SendReceiveTokensListAnalyticsLogger
    ) -> SendReceiveTokensListBuilder {
        SendReceiveTokensListBuilder(
            sourceTokenInput: sendSourceTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            expressRepository: expressDependenciesFactory.expressRepository,
            receiveTokenBuilder: makeSendReceiveTokenBuilder(),
            analyticsLogger: analyticsLogger
        )
    }

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: makeFiatItem())
    }
}

struct SendBaseDataBuilderFactory {
    let walletModel: any WalletModel
    let emailDataProvider: any EmailDataProvider

    func makeSendBaseDataBuilder(
        input: SendBaseDataBuilderInput,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder
    ) -> SendBaseDataBuilder {
        CommonSendBaseDataBuilder(
            input: input,
            walletModel: walletModel,
            emailDataProvider: emailDataProvider,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )
    }
}

struct SendSuggestedWalletsFactory {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    func makeSuggestedWallets(walletModel: any WalletModel) -> [SendDestinationSuggestedWallet] {
        let ignoredAddresses = walletModel.addresses.map(\.value).toSet()
        let targetNetworkId = walletModel.tokenItem.blockchain.networkId

        return userWalletRepository.models.reduce(into: []) { partialResult, userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels

            partialResult += walletModels
                .filter { walletModel in
                    let blockchain = walletModel.tokenItem.blockchain
                    let shouldBeIncluded = { blockchain.supportsCompound || !ignoredAddresses.contains(walletModel.defaultAddressString) }

                    return blockchain.networkId == targetNetworkId && walletModel.isMainToken && shouldBeIncluded()
                }
                .map { walletModel in
                    SendDestinationSuggestedWallet(name: userWalletModel.name, address: walletModel.defaultAddressString)
                }
        }
    }
}
