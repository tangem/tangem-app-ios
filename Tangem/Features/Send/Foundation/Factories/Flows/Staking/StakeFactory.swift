//
//  StakeFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStaking
import struct TangemUI.TokenIconInfo

/// The single V2 staking flow factory, gated behind `Feature.stakingFlowV2`. Builds `StakeModel` over a
/// per-network `StakingFlowProvider` and assembles the step graph from the provider's `stepPlan`,
/// replacing the four legacy `*FlowFactory` types.
class StakeFactory: StakingFlowDependenciesFactory {
    @Injected(\.marketingCampaignsRepository) private var marketingCampaignsRepository: MarketingCampaignsRepository
    @Injected(\.keysManager) private var keysManager: KeysManager

    let stakingableToken: SendStakingableToken
    let manager: any StakingManager
    let action: StakingAction
    let walletModelDependenciesProvider: WalletModelDependenciesProvider?

    var actionType: StakingAction.ActionType { action.displayType }

    /// A stakeable token always has a staking item — the staking manager is built from it — so its
    /// absence here is a programmer error (V2 was gated on for a token that can't stake).
    private var stakingItem: StakingTokenItem {
        guard let item = stakingableToken.tokenItem.stakingTokenItem else {
            preconditionFailure("stakingFlowV2 requires a token with a stakingTokenItem")
        }
        return item
    }

    lazy var analyticsLogger = makeStakingSendAnalyticsLogger()
    lazy var validationHandler = makeValidationHandler(
        stakingManager: manager,
        blockaidAPIKey: keysManager.blockaidAPIKey,
        analyticsLogger: analyticsLogger
    )
    lazy var provider: StakingFlowProvider = makeProvider()
    lazy var stakeModel = makeStakeModel()
    lazy var notificationManager = makeStakingNotificationManager(analyticsLogger: analyticsLogger)
    let autoupdatingTimer = AutoupdatingTimer()

    init(
        stakingableToken: SendStakingableToken,
        manager: any StakingManager,
        action: StakingAction,
        walletModelDependenciesProvider: WalletModelDependenciesProvider?
    ) {
        self.stakingableToken = stakingableToken
        self.manager = manager
        self.action = action
        self.walletModelDependenciesProvider = walletModelDependenciesProvider
    }
}

// MARK: - Provider & Model

extension StakeFactory {
    func makeProvider() -> StakingFlowProvider {
        let stages = StakeStagesResolver(
            stakingManager: manager,
            transactionValidator: stakingableToken.transactionValidator,
            feeIncludedCalculator: makeStakingFeeIncludedCalculator(),
            accountInitializationService: walletModelDependenciesProvider?.accountInitializationService,
            minimalBalanceProvider: walletModelDependenciesProvider?.minimalBalanceProvider,
            tokenItem: stakingableToken.tokenItem,
            feeTokenItem: stakingableToken.feeTokenItem
        )

        let minAmountValidator = StakingMinimumAmountValidator(
            tokenItem: tokenItem,
            action: actionType,
            stakingManagerStatePublisher: manager.statePublisher
        )

        return StakingFlowProviderFactory.make(
            network: stakingItem.network,
            contractAddress: stakingItem.contractAddress,
            action: action,
            stages: stages,
            minAmountValidator: minAmountValidator,
            preflightValidator: makeStakingPreflightValidator(),
            allowanceService: stakingableToken.allowanceService,
            tokenFeeProvidersManager: stakingableToken.tokenFeeProvidersManager
        )
    }

    func makeStakeModel() -> StakeModel {
        let stepPlan = provider.stepPlan
        return StakeModel(
            provider: provider,
            sendSourceToken: stakingableToken,
            accountInitializationService: walletModelDependenciesProvider?.accountInitializationService,
            validationHandler: validationHandler,
            analyticsLogger: analyticsLogger,
            autoupdatingTimer: autoupdatingTimer,
            initialAmount: makeInitialAmount(stepPlan: stepPlan),
            initialTarget: makeInitialTarget(stepPlan: stepPlan),
            // A flow with no editable amount and no validator to pick has nothing to wait for.
            shouldUpdateStateInitially: !stepPlan.amount.isEditable && !stepPlan.hasValidatorSelection
        )
    }

    private func makeInitialAmount(stepPlan: StakeStepPlan) -> SendAmount? {
        let crypto: Decimal? = switch stepPlan.amount {
        case .editable(let preset): preset
        case .fixed(let value): value
        }

        guard let crypto else { return nil }

        let fiat = tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(crypto, currencyId: $0) }
        return SendAmount(type: .typical(crypto: crypto, fiat: fiat))
    }

    /// A validator-selecting flow starts with no target (the user picks one); otherwise it's baked into
    /// the action.
    private func makeInitialTarget(stepPlan: StakeStepPlan) -> LoadingResult<StakingTargetInfo, Never> {
        guard !stepPlan.hasValidatorSelection else { return .loading }
        let baked = provider.makeAction(amount: nil, target: nil).targetType.target
        return baked.map { .success($0) } ?? .loading
    }
}

// MARK: - SendGenericFlowFactory

extension StakeFactory: SendGenericFlowFactory {
    func make(router: any SendRoutable, coordinatorStateProvider: SendCoordinatorStateProvider) -> SendViewModel {
        let stepPlan = provider.stepPlan

        // Amount: a full editable step when the amount is editable; otherwise compact/finish view models
        // for display only (the summary still shows the amount).
        let amountStep: SendAmountStep?
        let amountCompact: SendAmountCompactViewModel
        let amountFinish: SendAmountFinishViewModel
        var amountUpdater: SendAmountExternalUpdater?

        if stepPlan.amount.isEditable {
            let amount = makeSendAmountStep()
            amountStep = amount.step
            amountUpdater = amount.amountUpdater
            amountCompact = amount.compact
            amountFinish = amount.finish
        } else {
            amountStep = nil
            amountCompact = SendAmountCompactViewModel(
                initialSourceToken: stakingableToken,
                actionType: actionType.sendFlowActionType,
                sourceTokenInput: stakeModel,
                sourceTokenAmountInput: stakeModel
            )
            amountFinish = SendAmountFinishViewModel(
                flowActionType: actionType.sendFlowActionType,
                sourceTokenInput: stakeModel,
                sourceTokenAmountInput: stakeModel
            )
        }

        // Targets: a full step + compact when a validator is selectable; otherwise nothing.
        let targetsStep: StakingTargetsStep?
        let targetsCompact: StakingTargetsCompactViewModel?

        if stepPlan.hasValidatorSelection {
            let targets = makeStakingTargetsStep()
            targetsStep = targets.step
            targetsCompact = targets.compact
        } else {
            targetsStep = nil
            targetsCompact = nil
        }

        let sendFeeCompactViewModel = SendFeeCompactViewModel()
        let sendFeeFinishViewModel = SendFeeFinishViewModel()

        let summary = makeSendSummaryStep(
            sendAmountCompactViewModel: amountCompact,
            stakingTargetsCompactViewModel: targetsCompact,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let finish = makeSendFinishStep(
            sendAmountFinishViewModel: amountFinish,
            stakingTargetsCompactViewModel: targetsCompact,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router
        )

        // Steps
        sendFeeCompactViewModel.bind(input: stakeModel)
        sendFeeFinishViewModel.bind(input: stakeModel)

        // Notifications setup
        notificationManager.setup(provider: stakeModel, input: stakeModel)
        if let validationHandler {
            notificationManager.setup(
                validationStatePublisher: validationHandler.validationState,
                tokenName: tokenItem.currencySymbol
            )
        }
        notificationManager.setupManager(with: stakeModel)

        // Analytics
        analyticsLogger.setup(stakingTargetsInput: stakeModel)

        let stepsManager = StakeStepsManager(
            flowActionTypePublisher: stakeModel.flowActionTypePublisher,
            actionType: action.displayType,
            amountStep: amountStep,
            targetsStep: targetsStep,
            summaryStep: summary,
            finishStep: finish,
            summaryTitleProvider: makeStakingSummaryTitleProvider()
        )

        let viewModel = makeSendBase(stepsManager: stepsManager, router: router)
        summary.set(router: stepsManager)

        stakeModel.router = viewModel
        stakeModel.amountExternalUpdater = amountUpdater

        return viewModel
    }
}

// MARK: - SendBaseBuildable

extension StakeFactory: SendBaseBuildable {
    var baseIO: SendViewModelBuilder.IO {
        SendViewModelBuilder.IO(input: stakeModel, output: stakeModel)
    }

    var baseDependencies: SendViewModelBuilder.Dependencies {
        SendViewModelBuilder.Dependencies(
            alertBuilder: makeStakingAlertBuilder(),
            mailDataBuilder: CommonSendMailDataBuilder(
                baseDataInput: stakeModel,
                sourceTokenInput: stakeModel
            ),
            approveViewModelInputDataBuilder: CommonApproveViewModelInputDataBuilder(
                dataProvider: stakeModel,
                analyticsLogger: analyticsLogger,
                output: stakeModel,
                confirmTransactionPolicy: stakingableToken.confirmTransactionPolicy
            ),
            feeCurrencyProviderDataBuilder: CommonSendFeeCurrencyProviderDataBuilder(
                sourceTokenInput: stakeModel
            ),
            analyticsLogger: analyticsLogger,
            blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper(tokenItem: tokenItem),
            mainButtonUIOptionsProvider: CommonSendMainButtonUIOptionsProvider(sourceTokenInput: stakeModel)
        )
    }
}

// MARK: - SendAmountStepBuildable

extension StakeFactory: SendAmountStepBuildable {
    var amountIO: SendAmountStepBuilder.IO {
        SendAmountStepBuilder.IO(
            sourceIO: (input: stakeModel, output: stakeModel),
            sourceAmountIO: (input: stakeModel, output: stakeModel)
        )
    }

    var amountTypes: SendAmountStepBuilder.Types {
        .init(
            initialSourceToken: stakingableToken,
            flowActionType: actionType.sendFlowActionType
        )
    }

    var amountDependencies: SendAmountStepBuilder.Dependencies {
        let validator: SendAmountValidator
        let modifier: SendAmountModifier?

        switch action.type {
        case .unstake:
            validator = makeUnstakingAmountValidator()
            modifier = .none
        default:
            validator = StakingAmountValidator(
                tokenItem: tokenItem,
                validator: stakingableToken.transactionValidator,
                stakingManagerStatePublisher: manager.statePublisher,
                analyticsLogger: analyticsLogger
            )
            modifier = StakingAmountModifier(tokenItem: tokenItem, actionType: actionType.sendFlowActionType)
        }

        return SendAmountStepBuilder.Dependencies(
            sendAmountValidator: validator,
            amountModifier: modifier,
            notificationService: .none,
            analyticsLogger: analyticsLogger,
            // Campaigns are only placed on the staking entry screen, so the banner follows the enter actions.
            marketingBannerManager: action.type.isEnter ? makeMarketingBannerManager() : nil
        )
    }

    /// Solana keeps its own unstake rule: the remainder must stay above the network's minimum delegation.
    private func makeUnstakingAmountValidator() -> SendAmountValidator {
        switch tokenItem.blockchain {
        case .solana:
            return SolanaUnstakingAmountValidator(
                stakedAmount: action.amount,
                stakingManagerStatePublisher: manager.statePublisher
            )
        default:
            return UnstakingAmountValidator(
                tokenItem: tokenItem,
                stakedAmount: action.amount,
                stakingManagerStatePublisher: manager.statePublisher
            )
        }
    }

    private func makeMarketingBannerManager() -> MarketingBannerManager {
        marketingCampaignsRepository.loadCampaigns(for: .staking)

        let marketingBannerManager = MarketingBannerManager()
        marketingBannerManager.setup(
            bannersPublisher: marketingCampaignsRepository.bannersPublisher(for: tokenItem, kind: .staking)
        )

        return marketingBannerManager
    }
}

// MARK: - StakingTargetsStepBuildable

extension StakeFactory: StakingTargetsStepBuildable {
    var stakingTargetsIO: StakingTargetsStepBuilder.IO {
        StakingTargetsStepBuilder.IO(input: stakeModel, output: stakeModel)
    }

    var stakingTargetsTypes: StakingTargetsStepBuilder.Types {
        StakingTargetsStepBuilder.Types(actionType: actionType.sendFlowActionType, currentTarget: stakeModel.target)
    }

    var stakingTargetsDependencies: StakingTargetsStepBuilder.Dependencies {
        StakingTargetsStepBuilder.Dependencies(
            manager: manager,
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - SendSummaryStepBuildable

extension StakeFactory: SendSummaryStepBuildable {
    var summaryIO: SendSummaryStepBuilder.IO {
        SendSummaryStepBuilder.IO(
            input: stakeModel,
            output: stakeModel,
            validationStateProvider: stakeModel
        )
    }

    var summaryTypes: SendSummaryStepBuilder.Types {
        SendSummaryStepBuilder.Types(settings: provider.stepPlan.summarySettings)
    }

    var summaryDependencies: SendSummaryStepBuilder.Dependencies {
        SendSummaryStepBuilder.Dependencies(
            sendFeeProvider: stakeModel,
            notificationManager: notificationManager,
            // The summary step's appearance drives resume/pause of the approve-mining poll.
            autoupdatingTimer: autoupdatingTimer,
            analyticsLogger: analyticsLogger,
            sendDescriptionBuilder: makeSendTransactionSummaryDescriptionBuilder(),
            sendWithSwapDescriptionBuilder: makeSendWithSwapTransactionSummaryDescriptionBuilder(),
            stakingDescriptionBuilder: makeStakingTransactionSummaryDescriptionBuilder()
        )
    }
}

// MARK: - SendFinishStepBuildable

extension StakeFactory: SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO {
        SendFinishStepBuilder.IO(input: stakeModel)
    }

    var finishTypes: SendFinishStepBuilder.Types {
        SendFinishStepBuilder.Types(tokenItem: tokenItem)
    }

    var finishDependencies: SendFinishStepBuilder.Dependencies {
        SendFinishStepBuilder.Dependencies(
            analyticsLogger: analyticsLogger,
            headerTitleProvider: StakingFinishHeaderTitleProvider()
        )
    }
}
