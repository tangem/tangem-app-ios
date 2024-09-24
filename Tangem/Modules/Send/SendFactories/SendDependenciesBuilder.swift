//
//  SendDependenciesBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

struct SendDependenciesBuilder {
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func sendFlowActionType(actionType: StakingAction.ActionType) -> SendFlowActionType {
        switch actionType {
        case .stake: .stake
        case .unstake: .unstake
        case .pending(.claimRewards): .claimRewards
        case .pending(.withdraw): .withdraw
        case .pending(.restakeRewards): .restakeRewards
        case .pending(.voteLocked): .stake
        case .pending(.unlockLocked): .unlockLocked
        }
    }

    func summaryTitle(action: SendFlowActionType) -> String {
        switch action {
        case .send: Localization.sendSummaryTitle(walletModel.tokenItem.currencySymbol)
        case .approve, .stake: "\(Localization.commonStake) \(walletModel.tokenItem.currencySymbol)"
        case .unstake: action.title
        case .withdraw: action.title
        case .claimRewards: action.title
        case .restakeRewards: action.title
        case .unlockLocked: action.title
        default: action.title
        }
    }

    func summarySubtitle(action: SendFlowActionType) -> String? {
        switch action {
        case .send: walletName()
        case .approve, .stake: walletName()
        case .unstake: nil
        case .withdraw: nil
        case .claimRewards: nil
        case .restakeRewards: nil
        case .unlockLocked: nil
        default: nil
        }
    }

    func walletName() -> String {
        userWalletModel.name
    }

    func isFeeApproximate() -> Bool {
        walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType)
    }

    func makeTokenIconInfo() -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    func makeFiatIconURL() -> URL {
        IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: makeTokenIconInfo().imageURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: walletModel.quote == nil
        )
    }

    func makeFeeOptions() -> [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            return [.slow, .market, .fast]
        }

        return [.market]
    }

    func makeSendTransactionParametersBuilder() -> SendTransactionParametersBuilder {
        SendTransactionParametersBuilder(blockchain: walletModel.tokenItem.blockchain)
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

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
    }

    func makeSendTransactionDispatcher() -> SendTransactionDispatcher {
        SendTransactionDispatcherFactory(
            walletModel: walletModel,
            signer: userWalletModel.signer
        )
        .makeSendDispatcher()
    }

    func makeStakingTransactionDispatcher() -> SendTransactionDispatcher {
        StakingTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: userWalletModel.signer,
            pendingHashesSender: StakingDependenciesFactory().makePendingHashesSender(),
            stakingTransactionMapper: makeStakingTransactionMapper()
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

    func makeSendBaseDataBuilder(input: SendBaseDataBuilderInput) -> SendBaseDataBuilder {
        SendBaseDataBuilder(input: input, walletModel: walletModel, emailDataProvider: userWalletModel)
    }

    // MARK: - Send, Sell

    func makeSendModel(
        predefinedSellParameters: PredefinedSellParameters? = .none
    ) -> SendModel {
        let sendTransactionDispatcher = makeSendTransactionDispatcher()
        let predefinedValues = mapToPredefinedValues(sellParameters: predefinedSellParameters)

        return SendModel(
            walletModel: walletModel,
            sendTransactionDispatcher: sendTransactionDispatcher,
            transactionCreator: walletModel.transactionCreator,
            transactionSigner: userWalletModel.signer,
            feeIncludedCalculator: makeFeeIncludedCalculator(),
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            predefinedValues: predefinedValues
        )
    }

    func mapToPredefinedValues(sellParameters: PredefinedSellParameters?) -> SendModel.PredefinedValues {
        let source: SendModel.PredefinedValues.Source = sellParameters == nil ? .send : .sell
        let destination = sellParameters.map { SendAddress(value: $0.destination, source: .sellProvider) }
        let amount = sellParameters.map { sellParameters in
            let fiatValue = walletModel.tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(sellParameters.amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: sellParameters.amount, fiat: fiatValue))
        }

        // the additionalField is requried. Other can be optional
        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: walletModel.blockchainNetwork.blockchain) else {
                return .notSupported
            }

            guard let tag = sellParameters?.tag?.nilIfEmpty,
                  let params = try? makeSendTransactionParametersBuilder().transactionParameters(from: tag) else {
                return .empty(type: type)
            }

            return .filled(type: type, value: tag, params: params)
        }()

        return SendModel.PredefinedValues(source: source, destination: destination, tag: additionalField, amount: amount)
    }

    func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
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

    // MARK: - Staking

    func makeStakingModel(stakingManager: any StakingManager) -> StakingModel {
        StakingModel(
            stakingManager: stakingManager,
            transactionCreator: walletModel.transactionCreator,
            transactionValidator: walletModel.transactionValidator,
            feeIncludedCalculator: makeStakingFeeIncludedCalculator(),
            stakingTransactionDispatcher: makeStakingTransactionDispatcher(),
            sendTransactionDispatcher: makeSendTransactionDispatcher(),
            allowanceProvider: makeAllowanceProvider(),
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeUnstakingModel(stakingManager: any StakingManager, action: UnstakingModel.Action) -> UnstakingModel {
        UnstakingModel(
            stakingManager: stakingManager,
            sendTransactionDispatcher: makeStakingTransactionDispatcher(),
            transactionValidator: walletModel.transactionValidator,
            action: action,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeStakingNotificationManager() -> StakingNotificationManager {
        CommonStakingNotificationManager(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeStakingSendAmountValidator(stakingManager: any StakingManager) -> SendAmountValidator {
        StakingSendAmountValidator(
            tokenItem: walletModel.tokenItem,
            validator: walletModel.transactionValidator,
            stakingManagerStatePublisher: stakingManager.statePublisher
        )
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        StakingTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeAllowanceProvider() -> AllowanceProvider {
        CommonAllowanceProvider(walletModel: walletModel)
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

    func makeStakingAmountModifier() -> SendAmountModifier {
        StakingAmountModifier(tokenItem: walletModel.tokenItem)
    }
}
