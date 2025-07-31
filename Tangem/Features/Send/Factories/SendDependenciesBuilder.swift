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
    private let walletModel: any WalletModel
    private let userWalletModel: UserWalletModel
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let expressDependenciesFactory: ExpressDependenciesFactory

    init(userWalletModel: UserWalletModel, walletModel: any WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel

        expressDependenciesFactory = CommonExpressDependenciesFactory(
            userWalletModel: userWalletModel,
            initialWalletModel: walletModel,
            destinationWalletModel: .none,
            // We support only `CEX` in `Send With Swap` flow
            supportedProviderTypes: [.cex]
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

    func summaryTitle(action: SendFlowActionType) -> String {
        switch action {
        case .send:
            let assetName: String = switch walletModel.tokenItem.token?.metadata.kind {
            case .nonFungible: Localization.commonNft
            default: walletModel.tokenItem.currencySymbol
            }
            return Localization.sendSummaryTitle(assetName)
        case .approve, .stake:
            return "\(Localization.commonStake) \(walletModel.tokenItem.currencySymbol)"
        case .claimUnstaked:
            return SendFlowActionType.withdraw.title
        default:
            return action.title
        }
    }

    func summarySubtitle(action: SendFlowActionType) -> String? {
        switch action {
        case .send: walletName()
        case .approve, .stake, .restake: walletName()
        case .unstake: nil
        case .withdraw: nil
        case .claimRewards: nil
        case .restakeRewards: nil
        case .unlockLocked: nil
        default: nil
        }
    }

    func walletHeaderText(for actionType: SendFlowActionType) -> String {
        switch actionType {
        case .unstake: Localization.stakingStakedAmount
        default: walletName()
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

    func walletName() -> String {
        userWalletModel.name
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
            signer: userWalletModel.signer
        )
        .makeSendDispatcher()
    }

    func makeStakingTransactionDispatcher(
        stakingManger: some StakingManager,
        analyticsLogger: any StakingAnalyticsLogger
    ) -> TransactionDispatcher {
        StakingTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: userWalletModel.signer,
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

    func makeSendModel(
        analyticsLogger: any SendAnalyticsLogger,
        predefinedSellParameters: PredefinedSellParameters? = .none
    ) -> SendModel {
        let transactionDispatcher = makeTransactionDispatcher()
        let predefinedValues = mapToPredefinedValues(sellParameters: predefinedSellParameters)

        return SendModel(
            tokenItem: walletModel.tokenItem,
            balanceProvider: walletModel.availableBalanceProvider,
            transactionDispatcher: transactionDispatcher,
            transactionCreator: walletModel.transactionCreator,
            transactionSigner: userWalletModel.signer,
            feeIncludedCalculator: makeFeeIncludedCalculator(),
            analyticsLogger: analyticsLogger,
            predefinedValues: predefinedValues
        )
    }

    private func mapToPredefinedValues(sellParameters: PredefinedSellParameters?) -> SendModel.PredefinedValues {
        let destination = sellParameters.map { SendAddress(value: $0.destination, source: .sellProvider) }
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

    func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    func makeSendNewDestinationInteractorDependenciesProvider(analyticsLogger: any SendDestinationAnalyticsLogger) -> SendNewDestinationInteractorDependenciesProvider {
        SendNewDestinationInteractorDependenciesProvider(
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

    func makeSuggestedWallets() -> [SendSuggestedDestinationWallet] {
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
                    SendSuggestedDestinationWallet(name: userWalletModel.name, address: walletModel.defaultAddressString)
                }
        }
    }

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        switch walletModel.tokenItem.blockchain {
        case .koinos:
            KoinosSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        case .tron where walletModel.tokenItem.isToken:
            TronSendTransactionSummaryDescriptionBuilder(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem
            )
        default:
            CommonSendTransactionSummaryDescriptionBuilder(
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
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder? = .none
    ) -> SendBaseDataBuilder {
        CommonSendBaseDataBuilder(
            input: input,
            walletModel: walletModel,
            emailDataProvider: userWalletModel,
            sendReceiveTokensListBuilder: sendReceiveTokensListBuilder
        )
    }

    func makeCustomFeeService(input: any CustomFeeServiceInput) -> CustomFeeService? {
        CustomFeeServiceFactory(walletModel: walletModel).makeService(input: input)
    }

    func makeSendFeeLoader() -> SendFeeLoader {
        CommonSendFeeLoader(
            tokenItem: walletModel.tokenItem,
            walletModelFeeProvider: walletModel,
            shouldShowFeeSelector: walletModel.shouldShowFeeSelector
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

    func makeFeeSelectorCustomFeeFieldsBuilder(customFeeService: (any CustomFeeService)?) -> FeeSelectorCustomFeeFieldsBuilder {
        SendFeeSelectorCustomFeeFieldsBuilder(customFeeService: customFeeService)
    }

    func makeSendAnalyticsLogger(coordinatorSource: SendCoordinator.Source) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            coordinatorSource: coordinatorSource
        )
    }

    // MARK: - Send via swap

    func makeSendWithSwapModel(
        swapManager: SwapManager,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedSellParameters: PredefinedSellParameters? = .none
    ) -> SendWithSwapModel {
        let predefinedValues = mapToPredefinedValues(sellParameters: predefinedSellParameters)

        return SendWithSwapModel(
            userToken: makeSourceToken(),
            transactionSigner: userWalletModel.signer,
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
            wallet: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            tokenIconInfo: makeTokenIconInfo(),
            fiatItem: makeFiatItem(),
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
        CommonSendSourceTokenAmountValidator(input: input)
    }

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: makeFiatItem())
    }

    func makeSendReceiveTokensListBuilder(
        sendSourceTokenInput: SendSourceTokenInput,
        receiveTokenOutput: SendReceiveTokenOutput
    ) -> SendReceiveTokensListBuilder {
        SendReceiveTokensListBuilder(
            sourceTokenInput: sendSourceTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            expressRepository: expressDependenciesFactory.expressRepository,
            receiveTokenBuilder: makeSendReceiveTokenBuilder()
        )
    }

    func makeExpressProviderFormatter() -> ExpressProviderFormatter {
        .init(balanceFormatter: .init())
    }

    func makePriceChangeFormatter() -> PriceChangeFormatter {
        .init(percentFormatter: .init())
    }

    func makeExpressNotificationManager() -> ExpressNotificationManager {
        ExpressNotificationManager(expressInteractor: expressDependenciesFactory.expressInteractor)
    }

    func makeSendNewNotificationManager(receiveTokenInput: SendReceiveTokenInput?) -> SendNotificationManager {
        CommonSendNewNotificationManager(
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

    // MARK: - NFT support

    func makeNFTSendAmountValidator() -> SendAmountValidator {
        let nftSendUtil = NFTSendUtil(walletModel: walletModel, userWalletModel: userWalletModel)

        return NFTSendAmountValidator(expectedAmount: nftSendUtil.amountToSend)
    }

    func makeNFTSendAmountModifier() -> SendAmountModifier {
        let nftSendUtil = NFTSendUtil(walletModel: walletModel, userWalletModel: userWalletModel)

        return NFTSendAmountModifier(amount: nftSendUtil.amountToSend)
    }

    func makeNFTSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        return NFTSendTransactionSummaryDescriptionBuilder(feeTokenItem: walletModel.feeTokenItem)
    }

    // MARK: - Staking

    func makeStakingModel(
        stakingManager: some StakingManager,
        analyticsLogger: any StakingSendAnalyticsLogger
    ) -> StakingModel {
        StakingModel(
            stakingManager: stakingManager,
            transactionCreator: walletModel.transactionCreator,
            transactionValidator: walletModel.transactionValidator,
            feeIncludedCalculator: makeStakingFeeIncludedCalculator(),
            stakingTransactionDispatcher: makeStakingTransactionDispatcher(
                stakingManger: stakingManager,
                analyticsLogger: analyticsLogger
            ),
            transactionDispatcher: makeTransactionDispatcher(),
            allowanceService: makeAllowanceService(),
            analyticsLogger: analyticsLogger,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

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

    func makeStakingTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        StakingTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem)
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
        CommonStakingBaseDataBuilder(input: input, walletModel: walletModel, emailDataProvider: userWalletModel)
    }

    func makeStakingSendAnalyticsLogger(actionType: SendFlowActionType) -> StakingSendAnalyticsLogger {
        CommonStakingSendAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            actionType: actionType
        )
    }

    // MARK: - Onramp

    func makeOnrampModel(
        onrampManager: some OnrampManager,
        onrampDataRepository: some OnrampDataRepository,
        onrampRepository: some OnrampRepository,
        analyticsLogger: some OnrampSendAnalyticsLogger
    ) -> OnrampModel {
        OnrampModel(
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: walletModel,
            onrampManager: onrampManager,
            onrampDataRepository: onrampDataRepository,
            onrampRepository: onrampRepository,
            analyticsLogger: analyticsLogger
        )
    }

    func makeOnrampDependencies(userWalletId: String) -> (
        manager: OnrampManager,
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository
    ) {
        let apiProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userWalletModel: userWalletModel
        )

        let factory = TangemExpressFactory()

        // For UI tests, use UITestOnrampRepository with predefined values
        let repository: OnrampRepository
        if AppEnvironment.current.isUITest {
            repository = UITestOnrampRepository()
        } else {
            repository = factory.makeOnrampRepository(storage: CommonOnrampStorage())
        }

        let dataRepository = factory.makeOnrampDataRepository(expressAPIProvider: apiProvider)
        let manager = factory.makeOnrampManager(
            expressAPIProvider: apiProvider,
            onrampRepository: repository,
            dataRepository: dataRepository,
            analyticsLogger: CommonExpressAnalyticsLogger(tokenItem: walletModel.tokenItem)
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
            userWalletId: userWalletModel.userWalletId.stringValue,
            walletModel: walletModel,
            expressAPIProvider: ExpressAPIProviderFactory().makeExpressAPIProvider(userWalletModel: userWalletModel)
        )
    }

    func makeOnrampSendAnalyticsLogger(source: SendCoordinator.Source) -> OnrampSendAnalyticsLogger {
        CommonOnrampSendAnalyticsLogger(tokenItem: walletModel.tokenItem, source: source)
    }
}
