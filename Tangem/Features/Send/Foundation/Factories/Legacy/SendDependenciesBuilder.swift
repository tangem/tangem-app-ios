//
//  SendDependenciesBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemStaking
import BlockchainSdk
import TangemExpress
import TangemFoundation
import struct TangemUI.TokenIconInfo

struct SendDependenciesBuilder {
    private let input: Input
    private var walletModel: any WalletModel { input.walletModel }

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let expressDependenciesFactory: ExpressDependenciesFactory

    init(input: Input) {
        self.input = input

        expressDependenciesFactory = CommonExpressDependenciesFactory(
            input: input.expressInput,
            initialWallet: input.walletModel.asExpressInteractorWallet,
            destinationWallet: .none,
            // We support only `CEX` in `Send With Swap` flow
            supportedProviderTypes: [.cex],
            operationType: .swapAndSend
        )
    }

    func makeFiatItem() -> FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )
    }

    func sendFlowActionType(actionType: StakingAction.ActionType) -> SendFlowActionType {
        switch actionType {
        case .stake, .pending(.stake): .stake
        case .unstake: .unstake
        case .pending(.claimRewards): .claimRewards
        case .pending(.withdraw): .withdraw
        case .pending(.restakeRewards): .restakeRewards
        case .pending(.voteLocked): .voteLocked
        case .pending(.unlockLocked): .unlockLocked
        case .pending(.restake): .restake
        case .pending(.claimUnstaked): .claimUnstaked
        }
    }

    func walletHeaderText(for actionType: SendFlowActionType) -> String {
        switch actionType {
        case .unstake: Localization.stakingStakedAmount
        default: input.userWalletInfo.name
        }
    }

    func maxAmount(for amount: SendAmount?, actionType: SendFlowActionType) -> Decimal {
        switch actionType {
        case .unstake: amount?.crypto ?? 0
        default: walletModel.availableBalanceProvider.balanceType.value ?? 0
        }
    }

    func makeStakeAction() -> StakingAction {
        StakingAction(
            amount: walletModel.availableBalanceProvider.balanceType.value ?? 0,
            validatorType: .empty,
            type: .stake
        )
    }

    func formattedBalance(for amount: SendAmount?, actionType: SendFlowActionType) -> String {
        let balanceFormatted: BalanceFormatted
        switch actionType {
        case .unstake:
            let formatter = BalanceFormatter()
            let cryptoFormatted = formatter.formatCryptoBalance(
                amount?.crypto,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let fiatFormatted = formatter.formatFiatBalance(amount?.fiat)
            balanceFormatted = .init(crypto: cryptoFormatted, fiat: fiatFormatted)
        default:
            balanceFormatted = .init(
                crypto: walletModel.availableBalanceProvider.formattedBalanceType.value,
                fiat: walletModel.fiatAvailableBalanceProvider.formattedBalanceType.value
            )
        }
        return Localization.commonCryptoFiatFormat(balanceFormatted.crypto, balanceFormatted.fiat)
    }

    func isFeeApproximate() -> Bool {
        walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.tokenItem.amountType)
    }

    func makeTokenIconInfo() -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    func makeFiatIconURL() -> URL {
        IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func possibleToChangeAmountType() -> Bool {
        walletModel.quote != nil
    }

    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: makeTokenIconInfo().imageURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: !possibleToChangeAmountType()
        )
    }

    func makeFeeOptions() -> [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            return [.slow, .market, .fast]
        }

        return [.market]
    }

    func makeSendTransactionParametersBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: walletModel.tokenItem.blockchain)
    }

    func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: makeFeeOptions().count == 1)
    }

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            userWalletId: input.userWalletInfo.id,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider
        )
    }

    func makeInformationRelevanceService(input: SendFeeInput, output: SendFeeOutput, provider: SendFeeProvider) -> InformationRelevanceService {
        CommonInformationRelevanceService(input: input, output: output, provider: provider)
    }

    func makeTransactionDispatcher() -> TransactionDispatcher {
        TransactionDispatcherFactory(
            walletModel: walletModel,
            signer: input.userWalletInfo.signer
        )
        .makeSendDispatcher()
    }

    func makeStakingTransactionDispatcher(
        stakingManger: some StakingManager,
        analyticsLogger: any StakingAnalyticsLogger
    ) -> TransactionDispatcher {
        StakingTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: input.userWalletInfo.signer,
            pendingHashesSender: StakingDependenciesFactory().makePendingHashesSender(),
            stakingTransactionMapper: makeStakingTransactionMapper(),
            analyticsLogger: analyticsLogger,
            transactionStatusProvider: CommonStakeKitTransactionStatusProvider(stakingManager: stakingManger)
        )
    }

    func makeSendQRCodeService() -> SendQRCodeService {
        CommonSendQRCodeService(
            parser: QRCodeParser(
                amountType: walletModel.tokenItem.amountType,
                blockchain: walletModel.tokenItem.blockchain,
                decimalCount: walletModel.tokenItem.decimalCount
            )
        )
    }

    func makeFeeIncludedCalculator() -> FeeIncludedCalculator {
        CommonFeeIncludedCalculator(validator: walletModel.transactionValidator)
    }

    // MARK: - Send, Sell

    func mapToPredefinedValues(sellParameters: PredefinedSellParameters?) -> SendModel.PredefinedValues {
        let destination = sellParameters.map { SendDestination(value: .plain($0.destination), source: .sellProvider) }
        let amount = sellParameters.map { sellParameters in
            let fiatValue = walletModel.tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(sellParameters.amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: sellParameters.amount, fiat: fiatValue))
        }

        // the additionalField is required. Other can be optional
        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: walletModel.tokenItem.blockchain) else {
                return .notSupported
            }

            guard let tag = sellParameters?.tag?.nilIfEmpty,
                  let params = try? makeSendTransactionParametersBuilder().transactionParameters(value: tag) else {
                return .empty(type: type)
            }

            return .filled(type: type, value: tag, params: params)
        }()

        return SendModel.PredefinedValues(
            destination: destination,
            tag: additionalField,
            amount: amount
        )
    }

    func makeTokenBalanceProvider() -> TokenBalanceProvider {
        walletModel.availableBalanceProvider
    }

    func makeSendDestinationInteractorDependenciesProvider(analyticsLogger: any SendDestinationAnalyticsLogger) -> SendDestinationInteractorDependenciesProvider {
        SendDestinationInteractorDependenciesProvider(
            receivedTokenType: .same(makeSourceToken()),
            sendingWalletData: .init(
                walletAddresses: walletModel.addresses.map(\.value),
                suggestedWallets: makeSuggestedWallets(),
                destinationTransactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
                analyticsLogger: analyticsLogger
            )
        )
    }

    func makeSendDestinationValidator() -> SendDestinationValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.tokenItem.blockchain).makeAddressService()
        let validator = CommonSendDestinationValidator(
            walletAddresses: walletModel.addresses.map { $0.value },
            addressService: addressService,
            supportsCompound: walletModel.tokenItem.blockchain.supportsCompound
        )

        return validator
    }

    func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(
            transactionHistoryUpdater: walletModel,
            transactionHistoryMapper: makeTransactionHistoryMapper()
        )
    }

    func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses.map { $0.value },
            showSign: false
        )
    }

    func makeAddressResolver() -> AddressResolver? {
        let addressResolverFactory = AddressResolverFactoryProvider().factory
        let addressResolver = addressResolverFactory.makeAddressResolver(for: walletModel.tokenItem.blockchain)
        return addressResolver
    }

    func makeSuggestedWallets() -> [SendDestinationSuggestedWallet] {
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

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        if case .nonFungible = walletModel.tokenItem.token?.metadata.kind {
            return NFTSendTransactionSummaryDescriptionBuilder(feeTokenItem: walletModel.feeTokenItem)
        }

        switch walletModel.tokenItem.blockchain {
        case .koinos:
            return KoinosSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        case .tron where walletModel.tokenItem.isToken:
            return TronSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        default:
            return CommonSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        }
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeSendBaseDataBuilder(
        input: SendBaseDataBuilderInput,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder
    ) -> SendBaseDataBuilder {
        CommonSendBaseDataBuilder(
            input: input,
            walletModel: walletModel,
            emailDataProvider: self.input.userWalletInfo.emailDataProvider,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )
    }

    func makeCustomFeeService(input: any CustomFeeServiceInput) -> CustomFeeService? {
        CustomFeeServiceFactory(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            bitcoinTransactionFeeCalculator: walletModel.bitcoinTransactionFeeCalculator
        ).makeService(input: input)
    }

    func makeSendFeeLoader() -> SendFeeLoader {
        CommonSendFeeLoader(
            tokenItem: walletModel.tokenItem,
            walletModelFeeProvider: walletModel
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

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            sendType: sendType
        )
    }

    func makeBlockchainSDKNotificationMapper() -> BlockchainSDKNotificationMapper {
        BlockchainSDKNotificationMapper(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeSendSummaryTitleProvider() -> SendSummaryTitleProvider {
        CommonSendSummaryTitleProvider(tokenItem: walletModel.tokenItem, walletName: input.userWalletInfo.name)
    }

    // MARK: - Sell

    func makeSellSendSummaryTitleProvider() -> SendSummaryTitleProvider {
        SellSendSummaryTitleProvider()
    }

    // MARK: - Send via swap

    func makeSendWithSwapModel(
        swapManager: SwapManager,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: SendModel.PredefinedValues = .init()
    ) -> SendModel {
        SendModel(
            userToken: makeSourceToken(),
            transactionSigner: input.userWalletInfo.signer,
            feeIncludedCalculator: makeFeeIncludedCalculator(),
            analyticsLogger: analyticsLogger,
            sendReceiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            swapManager: swapManager,
            predefinedValues: predefinedValues
        )
    }

    func makeSourceToken() -> SendSourceToken {
        SendSourceToken(
            wallet: input.userWalletInfo.name,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            tokenIconInfo: makeTokenIconInfo(),
            fiatItem: makeFiatItem(),
            possibleToConvertToFiat: possibleToChangeAmountType(),
            availableBalanceProvider: walletModel.availableBalanceProvider,
            fiatAvailableBalanceProvider: walletModel.fiatAvailableBalanceProvider,
            transactionValidator: walletModel.transactionValidator,
            transactionCreator: walletModel.transactionCreator,
            transactionDispatcher: makeTransactionDispatcher()
        )
    }

    func makeSwapManager() -> SwapManager {
        CommonSwapManager(interactor: expressDependenciesFactory.expressInteractor)
    }

    func makeSendSourceTokenAmountValidator(input: any SendSourceTokenInput) -> SendAmountValidator {
        CommonSendAmountValidator(input: input)
    }

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: makeFiatItem())
    }

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

    func makeExpressProviderFormatter() -> ExpressProviderFormatter {
        .init(balanceFormatter: .init())
    }

    func makePriceChangeFormatter() -> PriceChangeFormatter {
        .init(percentFormatter: .init())
    }

    func makeExpressNotificationManager() -> ExpressNotificationManager {
        ExpressNotificationManager(
            userWalletId: input.userWalletInfo.id,
            expressInteractor: expressDependenciesFactory.expressInteractor
        )
    }

    func makeSendNewNotificationManager(receiveTokenInput: SendReceiveTokenInput?) -> SendNotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: makeSendNotificationManager(),
            expressNotificationManager: makeExpressNotificationManager()
        )
    }

    func makeSwapFeeProvider(swapManager: SwapManager) -> SendFeeProvider {
        SwapFeeProvider(swapManager: swapManager)
    }

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

    func makeSwapTransactionSummaryDescriptionBuilder() -> SwapTransactionSummaryDescriptionBuilder {
        CommonSwapTransactionSummaryDescriptionBuilder(
            sendTransactionSummaryDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
        )
    }

    func makeSendWithSwapSummaryTitleProvider(receiveTokenInput: SendReceiveTokenInput) -> SendSummaryTitleProvider {
        SendWithSwapSummaryTitleProvider(receiveTokenInput: receiveTokenInput)
    }

    // MARK: - NFT support

    func makePredefinedNFTValues() -> SendModel.PredefinedValues {
        .init(amount: .init(type: .typical(crypto: NFTSendUtil.amountToSend, fiat: .none)))
    }

    // MARK: - Staking

    func makeUnstakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger,
        action: UnstakingModel.Action,
    ) -> UnstakingModel {
        UnstakingModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionValidator: walletModel.transactionValidator,
            analyticsLogger: analyticsLogger,
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeRestakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger,
        action: RestakingModel.Action
    ) -> RestakingModel {
        RestakingModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionValidator: walletModel.transactionValidator,
            sendAmountValidator: makeRestakingSendAmountValidator(stakingManager: stakingManager, action: action.type),
            analyticsLogger: analyticsLogger,
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingSingleActionModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger,
        action: UnstakingModel.Action
    ) -> StakingSingleActionModel {
        StakingSingleActionModel(
            stakingManager: stakingManager,
            transactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionValidator: walletModel.transactionValidator,
            analyticsLogger: analyticsLogger,
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingNotificationManager() -> StakingNotificationManager {
        CommonStakingNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeStakingSendAmountValidator(
        stakingManager: some StakingManager
    ) -> SendAmountValidator {
        StakingAmountValidator(
            tokenItem: walletModel.tokenItem,
            validator: walletModel.transactionValidator,
            stakingManagerStatePublisher: stakingManager.statePublisher
        )
    }

    func makeRestakingSendAmountValidator(
        stakingManager: some StakingManager,
        action: StakingAction.ActionType
    ) -> SendAmountValidator {
        RestakingAmountValidator(
            tokenItem: walletModel.tokenItem,
            action: action,
            stakingManagerStatePublisher: stakingManager.statePublisher
        )
    }

    func makeUnstakingSendAmountValidator(
        stakingManager: some StakingManager,
        stakedAmount: Decimal
    ) -> SendAmountValidator {
        UnstakingAmountValidator(
            tokenItem: walletModel.tokenItem,
            stakedAmount: stakedAmount,
            stakingManagerStatePublisher: stakingManager.statePublisher
        )
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder {
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem)
    }

    func makeAllowanceService() -> AllowanceService {
        CommonAllowanceService(
            tokenItem: walletModel.tokenItem,
            allowanceChecker: .init(
                blockchain: walletModel.tokenItem.blockchain,
                amountType: walletModel.tokenItem.amountType,
                walletAddress: walletModel.defaultAddressString,
                ethereumNetworkProvider: walletModel.ethereumNetworkProvider,
                ethereumTransactionDataBuilder: walletModel.ethereumTransactionDataBuilder
            )
        )
    }

    func makeStakingTransactionMapper() -> StakingTransactionMapper {
        StakingTransactionMapper(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingAlertBuilder() -> SendAlertBuilder {
        StakingSendAlertBuilder()
    }

    func makeStakingFeeIncludedCalculator() -> FeeIncludedCalculator {
        StakingFeeIncludedCalculator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    func makeStakingAmountModifier(actionType: SendFlowActionType) -> SendAmountModifier {
        StakingAmountModifier(tokenItem: walletModel.tokenItem, actionType: actionType)
    }

    func makeStakingBaseDataBuilder(input: StakingBaseDataBuilderInput) -> StakingBaseDataBuilder {
        CommonStakingBaseDataBuilder(input: input, walletModel: walletModel, emailDataProvider: self.input.userWalletInfo.emailDataProvider)
    }

    func makeStakingSendAnalyticsLogger(actionType: SendFlowActionType) -> StakingSendAnalyticsLogger {
        CommonStakingSendAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            actionType: actionType
        )
    }

    func makeStakingSummaryTitleProvider(actionType: SendFlowActionType) -> SendSummaryTitleProvider {
        StakingSendSummaryTitleProvider(actionType: actionType, tokenItem: walletModel.tokenItem, walletName: input.userWalletInfo.name)
    }

    // MARK: - Onramp

    func makeOnrampModel(
        onrampManager: some OnrampManager,
        onrampDataRepository: some OnrampDataRepository,
        onrampRepository: some OnrampRepository,
        analyticsLogger: some OnrampSendAnalyticsLogger,
        predefinedValues: OnrampModel.PredefinedValues
    ) -> OnrampModel {
        OnrampModel(
            userWalletId: input.userWalletInfo.id.stringValue,
            tokenItem: walletModel.tokenItem,
            defaultAddressString: walletModel.defaultAddressString,
            onrampManager: onrampManager,
            onrampDataRepository: onrampDataRepository,
            onrampRepository: onrampRepository,
            analyticsLogger: analyticsLogger,
            predefinedValues: predefinedValues
        )
    }

    func makeOnrampDependencies(preferredValues: PreferredValues) -> (
        manager: OnrampManager,
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository
    ) {
        let apiProvider = expressDependenciesFactory.expressAPIProvider
        let repository: OnrampRepository = expressDependenciesFactory.onrampRepository

        let factory = TangemExpressFactory()
        let dataRepository = factory.makeOnrampDataRepository(expressAPIProvider: apiProvider)
        let sortType: ProviderItemSorter.SortType = if FeatureProvider.isAvailable(.newOnrampUI) { .byOnrampProviderExpectedAmount
        } else {
            .byPaymentMethodPriority
        }

        let manager = factory.makeOnrampManager(
            expressAPIProvider: apiProvider,
            onrampRepository: repository,
            dataRepository: dataRepository,
            analyticsLogger: CommonExpressAnalyticsLogger(tokenItem: walletModel.tokenItem),
            providerItemSorter: ProviderItemSorter(sortType: sortType),
            preferredValues: preferredValues
        )

        return (
            manager: manager,
            repository: repository,
            dataRepository: dataRepository
        )
    }

    func makeOnrampBaseDataBuilder(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        providersBuilder: OnrampProvidersBuilder,
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) -> OnrampBaseDataBuilder {
        CommonOnrampBaseDataBuilder(
            config: input.userWalletInfo.config,
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            providersBuilder: providersBuilder,
            paymentMethodsBuilder: paymentMethodsBuilder,
            onrampRedirectingBuilder: onrampRedirectingBuilder
        )
    }

    func makeOnrampNotificationManager(input: OnrampNotificationManagerInput, delegate: NotificationTapDelegate) -> OnrampNotificationManager {
        CommonOnrampNotificationManager(input: input, delegate: delegate)
    }

    func makePendingExpressTransactionsManager() -> PendingExpressTransactionsManager {
        CommonPendingOnrampTransactionsManager(
            userWalletId: input.userWalletInfo.id.stringValue,
            walletModel: walletModel,
            expressAPIProvider: expressDependenciesFactory.expressAPIProvider
        )
    }

    func makeOnrampSendAnalyticsLogger(source: SendCoordinator.Source) -> OnrampSendAnalyticsLogger {
        CommonOnrampSendAnalyticsLogger(tokenItem: walletModel.tokenItem, source: source)
    }

    func makeOnrampSummaryTitleProvider() -> SendSummaryTitleProvider {
        OnrampSendSummaryTitleProvider(tokenItem: walletModel.tokenItem)
    }
}

extension SendDependenciesBuilder {
    typealias Input = SendInput
}
