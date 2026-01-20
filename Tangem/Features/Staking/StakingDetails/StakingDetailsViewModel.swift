//
//  StakingDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemAssets
import TangemStaking
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers
import TangemUI
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class StakingDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { Localization.stakingDetailsTitle(tokenItem.name) }

    @Published var hideStakingInfoBanner = true
    @Published var detailsViewModels: [DefaultRowViewModel] = []

    @Published var rewardViewData: RewardViewData?
    @Published var stakes: [StakingDetailsStakeViewData] = []
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?
    @Published var actionButtonLoading: Bool = false
    @Published var actionButtonState: ActionButtonState = .enabled
    @Published var actionButtonType: ActionButtonType?
    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var alert: AlertBinder?

    private(set) lazy var scrollViewStateObject: RefreshScrollViewStateObject = .init(
        settings: .init(stopRefreshingDelay: .zero),
        refreshable: { [weak self] in
            await self?.refresh()
        }
    )

    lazy var legalText = makeLegalText()

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let tokenBalanceProvider: TokenBalanceProvider
    private let stakingManager: StakingManager
    private weak var coordinator: StakingDetailsRoutable?

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var percentFormatter = PercentFormatter()
    private lazy var dateFormatter = DateComponentsFormatter.staking()
    private lazy var stakesBuilder = StakingDetailsStakeViewDataBuilder(tokenItem: tokenItem)

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        tokenBalanceProvider: TokenBalanceProvider,
        stakingManager: StakingManager,
        coordinator: StakingDetailsRoutable
    ) {
        self.tokenItem = tokenItem
        self.tokenBalanceProvider = tokenBalanceProvider
        self.stakingManager = stakingManager
        self.coordinator = coordinator

        bind()
    }

    func userDidTapBanner() {
        coordinator?.openWhatIsStaking()
    }

    func userDidTapActionButton() {
        guard stakingManager.state.yieldInfo?.preferredTargets.allSatisfy({ $0.status == .full }) == false else {
            alert = .init(
                title: Localization.stakingErrorNoValidatorsTitle,
                message: Localization.stakingNoValidatorsErrorMessage
            )
            return
        }

        if case .disabled = actionButtonState {
            showStakeMoreWarningIfNeeded()
            return
        }

        guard stakingManager.state.yieldInfo?.preferredTargets.isEmpty == false else {
            alert = .init(title: Localization.commonWarning, message: Localization.stakingNoValidatorsErrorMessage)
            return
        }

        coordinator?.openStakingFlow()
    }

    func onAppear() {
        runTask(in: self) { await $0.refresh() }

        let balances = stakingManager.balances.flatMap { String($0.count) } ?? String(0)
        Analytics.log(
            event: .stakingInfoScreenOpened,
            params: [
                .validatorsCount: balances,
                .token: tokenItem.currencySymbol,
            ],
            analyticsSystems: .all
        )
    }
}

// MARK: - Private

private extension StakingDetailsViewModel {
    func bind() {
        tokenBalanceProvider.balanceTypePublisher
            .combineLatest(stakingManager.statePublisher)
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { state in
                let (viewModel, (_, stakingManagerState)) = state
                viewModel.setupView(state: stakingManagerState)
            }
            .store(in: &bag)

        tokenBalanceProvider
            .balanceTypePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.setupMainActionButton(state: state)
            }
            .store(in: &bag)
    }

    func refresh() async {
        await stakingManager.updateState(loadActions: true)
    }

    func setupMainActionButton(state: TokenBalanceType) {
        switch state {
        case .empty, .loading:
            break
        // Only with positive balance
        case .loaded(let balance) where balance > 0:
            actionButtonState = .enabled
        case .failure, .loaded:
            actionButtonState = .disabled(reason: .insufficientFunds)
        }
    }

    func setupView(state: StakingManagerState) {
        switch state {
        case .loading:
            actionButtonLoading = true
        case .loadingError:
            actionButtonLoading = false
            actionButtonType = .none
        case .notEnabled:
            actionButtonLoading = false
            actionButtonType = .none
        case .temporaryUnavailable(let yieldInfo), .availableToStake(let yieldInfo):
            setupView(yield: yieldInfo, balances: [])

            actionButtonLoading = false
            actionButtonType = .stake
        case .staked(let staked):
            setupView(yield: staked.yieldInfo, balances: staked.balances)

            actionButtonLoading = false
            actionButtonState = staked.canStakeMore ? .enabled : .disabled(reason: .cantStakeMore)
            actionButtonType = .stakeMore
        }
    }

    func setupView(yield: StakingYieldInfo, balances: [StakingBalance]) {
        setupHeaderView(hasBalances: !balances.isEmpty)
        setupDetailsSection(yield: yield)
        setupStakes(yield: yield, staking: balances.stakes())
        setupRewardView(yield: yield, balances: balances)
    }

    func setupHeaderView(hasBalances: Bool) {
        hideStakingInfoBanner = hasBalances
    }

    func setupDetailsSection(yield: StakingYieldInfo) {
        var viewModels = [
            DefaultRowViewModel(
                title: yield.rewardType.title,
                detailsType: .text(yield.rewardRateValues.formatted(formatter: percentFormatter)),
                accessibilityIdentifier: StakingAccessibilityIdentifiers.annualPercentageRateValue,
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(title: yield.rewardType.title, description: yield.rewardType.info)
                }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsAvailable,
                detailsType: .text(tokenBalanceProvider.formattedBalanceType.value, sensitive: true),
                accessibilityIdentifier: StakingAccessibilityIdentifiers.availableValue
            ),
        ]

        if shouldShowMinimumRequirement() {
            let minimumFormatted = balanceFormatter.formatCryptoBalance(
                yield.enterMinimumRequirement,
                currencyCode: tokenItem.currencySymbol
            )

            viewModels.append(
                DefaultRowViewModel(
                    title: Localization.stakingDetailsMinimumRequirement,
                    detailsType: .text(minimumFormatted)
                )
            )
        }

        viewModels.append(
            contentsOf: [
                DefaultRowViewModel(
                    title: Localization.stakingDetailsUnbondingPeriod,
                    detailsType: .text(yield.unbondingPeriod.formatted(formatter: dateFormatter)),
                    accessibilityIdentifier: StakingAccessibilityIdentifiers.unbondingPeriodValue,
                    secondaryAction: { [weak self] in
                        self?.openBottomSheet(
                            title: Localization.stakingDetailsUnbondingPeriod,
                            description: Localization.stakingDetailsUnbondingPeriodInfo
                        )
                    }
                ),
                DefaultRowViewModel(
                    title: Localization.stakingDetailsRewardClaiming,
                    detailsType: .text(yield.rewardClaimingType.title),
                    accessibilityIdentifier: StakingAccessibilityIdentifiers.rewardClaimingValue,
                    secondaryAction: { [weak self] in
                        self?.openBottomSheet(
                            title: Localization.stakingDetailsRewardClaiming,
                            description: Localization.stakingDetailsRewardClaimingInfo
                        )
                    }
                ),
            ]
        )

        if !yield.warmupPeriod.isZero {
            viewModels.append(DefaultRowViewModel(
                title: Localization.stakingDetailsWarmupPeriod,
                detailsType: .text(yield.warmupPeriod.formatted(formatter: dateFormatter)),
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(
                        title: Localization.stakingDetailsWarmupPeriod,
                        description: Localization.stakingDetailsWarmupPeriodInfo
                    )
                }
            ))
        }

        viewModels.append(
            DefaultRowViewModel(
                title: Localization.stakingDetailsRewardSchedule,
                detailsType: .text(yield.rewardScheduleType.formatted()),
                accessibilityIdentifier: StakingAccessibilityIdentifiers.rewardScheduleValue,
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(
                        title: Localization.stakingDetailsRewardSchedule,
                        description: Localization.stakingDetailsRewardScheduleInfo
                    )
                }
            )
        )

        detailsViewModels = viewModels
    }

    func setupRewardView(yield: StakingYieldInfo, balances: [StakingBalance]) {
        guard !balances.isEmpty else {
            rewardViewData = nil
            return
        }

        let rewards = balances.rewards()
        switch rewards.sum() {
        case .zero where yield.rewardClaimingType == .auto:
            rewardViewData = RewardViewData(state: .automaticRewards, networkType: yield.item.network)
        case .zero:
            rewardViewData = RewardViewData(state: .noRewards, networkType: yield.item.network)
        case let rewardsValue:
            let rewardsCryptoFormatted = balanceFormatter.formatCryptoBalance(
                rewardsValue,
                currencyCode: tokenItem.currencySymbol
            )
            let rewardsFiat = tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(rewardsValue, currencyId: $0)
            }
            let rewardsFiatFormatted = balanceFormatter.formatFiatBalance(rewardsFiat)
            let rewardsClaimable = balances.flatMap(\.actions).contains(where: { $0.type == .claimRewards })
            rewardViewData = RewardViewData(
                state: .rewards(
                    claimable: rewardsClaimable,
                    fiatFormatted: rewardsFiatFormatted,
                    cryptoFormatted: rewardsCryptoFormatted
                ) { [weak self] in
                    if rewardsClaimable {
                        self?.openRewardsFlow(rewardsBalances: rewards, yield: yield)
                    } else {
                        self?.showRewardsClaimableWarningIfNeeded(
                            balances: balances,
                            yield: yield,
                            rewardsValue: rewardsValue
                        )
                    }
                },
                networkType: yield.item.network
            )
        }
    }

    func setupStakes(yield: StakingYieldInfo, staking: [StakingBalance]) {
        let staking = staking.map { balance in
            stakesBuilder.mapToStakingDetailsStakeViewData(yield: yield, balance: balance) { [weak self] in
                let tokenCurrencySymbol = self?.tokenItem.currencySymbol ?? ""

                Analytics.log(
                    event: .stakingButtonValidator,
                    params: [
                        .source: Analytics.ParameterValue.stakeSourceStakeInfo.rawValue,
                        .token: tokenCurrencySymbol,
                    ]
                )
                self?.openFlow(balance: balance, targets: yield.targets)
            }
        }

        stakes = staking.sorted(by: { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }

            return lhs.balance.crypto > rhs.balance.crypto
        })
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
    }

    func openFlow(balance: StakingBalance, targets: [StakingTargetInfo]) {
        do {
            let action = try PendingActionMapper(balance: balance, validators: targets).getAction()
            switch action {
            case .single(let action):
                openFlow(for: action)
            case .multiple(let actions):
                let buttons = actions.map { action in
                    ConfirmationDialogViewModel.Button(title: action.displayType.title) { [weak self] in
                        self?.openFlow(for: action)
                    }
                }

                confirmationDialog = ConfirmationDialogViewModel(
                    title: Localization.commonSelectAction,
                    buttons: buttons + [ConfirmationDialogViewModel.Button.cancel]
                )
            }
        } catch {
            alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
        }
    }

    private func openRewardsFlow(rewardsBalances: [StakingBalance], yield: StakingYieldInfo) {
        if let rewardsBalance = rewardsBalances.singleElement {
            openFlow(balance: rewardsBalance, targets: yield.targets)

            let name = rewardsBalance.targetType.target?.name
            Analytics.log(
                event: .stakingButtonRewards,
                params: [
                    .validator: name ?? "",
                    .token: tokenItem.currencySymbol,
                ]
            )
        } else {
            coordinator?.openMultipleRewards()
        }
    }

    func showRewardsClaimableWarningIfNeeded(
        balances: [StakingBalance],
        yield: StakingYieldInfo,
        rewardsValue: Decimal
    ) {
        let constraint = balances
            .compactMap(\.actionConstraints)
            .flatMap(\.self)
            .first(where: { $0.type == .claimRewards })

        let minAmount: Decimal? = switch constraint?.amount.minimum {
        // StakeKit didn't implement constraints for polygon yet, this code will be removed once done
        case .none where yield.item.network == .ethereum
            && yield.item.contractAddress == StakingConstants.polygonContractAddress: 1
        case .none: .none
        case .some(let amount): amount
        }

        guard let minAmount, minAmount > rewardsValue else { return }

        let minAmountString = balanceFormatter.formatCryptoBalance(
            minAmount,
            currencyCode: tokenItem.currencySymbol
        )

        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: "",
            message: Localization.stakingDetailsMinRewardsNotification(yield.item.name, minAmountString),
            buttonText: Localization.warningButtonOk
        )
    }

    func showStakeMoreWarningIfNeeded() {
        if case .disabled(let reason) = actionButtonState, case .cantStakeMore = reason {
            alert = .init(
                title: Localization.commonAttention,
                message: Localization.stakingStakeMoreButtonUnavailabilityReason(
                    tokenItem.blockchain.displayName,
                    tokenItem.blockchain.currencySymbol
                )
            )
        }
    }

    private func openFlow(for action: StakingAction) {
        let stakingParams = StakingBlockchainParams(blockchain: tokenItem.blockchain)
        switch action.type {
        case .stake,
             .pending(.stake) where stakingParams.isStakingAmountEditable:
            coordinator?.openStakingFlow()
        case .pending(.voteLocked):
            coordinator?.openRestakingFlow(action: action)
        case .unstake where stakingParams.reservedFee > 0:
            if checkIfTokenBalanceIsSufficient(for: stakingParams.reservedFee) {
                fallthrough
            }
        case .unstake:
            coordinator?.openUnstakingFlow(action: action)
        case .pending(.restake), .pending(.stake):
            coordinator?.openRestakingFlow(action: action)
        case .pending(.withdraw) where stakingParams.reservedFee > 0:
            if checkIfTokenBalanceIsSufficient(for: stakingParams.reservedFee) {
                fallthrough
            }
        case .pending:
            coordinator?.openStakingSingleActionFlow(action: action)
        }
    }

    private func checkIfTokenBalanceIsSufficient(for reservedFee: Decimal) -> Bool {
        guard let balance = tokenBalanceProvider.balanceType.value,
              balance < reservedFee else {
            return true
        }
        alert = .init(
            title: Localization.stakingNotificationTonExtraReserveTitle,
            message: Localization.stakingNotificationTonExtraReserveIsRequired
        )
        return false
    }

    func shouldShowMinimumRequirement() -> Bool {
        switch tokenItem.blockchain {
        case .polkadot, .binance, .cardano, .polygon: true
        default: false
        }
    }

    func makeLegalText() -> AttributedString {
        let tos = Localization.commonTermsOfUse
        let policy = Localization.commonPrivacyPolicy

        func makeBaseAttributedString(for text: String) -> AttributedString {
            var attributedString = AttributedString(text)
            attributedString.font = Fonts.Regular.footnote
            attributedString.foregroundColor = Colors.Text.tertiary
            return attributedString
        }

        func formatLink(in attributedString: inout AttributedString, textToSearch: String, url: URL) {
            guard let range = attributedString.range(of: textToSearch) else {
                return
            }

            attributedString[range].link = url
            attributedString[range].foregroundColor = Colors.Text.accent
        }

        var attributedString = makeBaseAttributedString(for: Localization.stakingLegal(tos, policy))
        formatLink(in: &attributedString, textToSearch: tos, url: stakingManager.tosURL)
        formatLink(in: &attributedString, textToSearch: policy, url: stakingManager.privacyPolicyURL)
        return attributedString
    }
}

extension StakingDetailsViewModel {
    enum ActionButtonType: Hashable {
        case stake
        case stakeMore

        var title: String {
            switch self {
            case .stake: Localization.commonStake
            case .stakeMore: Localization.stakingStakeMore
            }
        }
    }

    enum DisableReason: Hashable {
        case cantStakeMore
        case insufficientFunds
    }

    enum ActionButtonState: Hashable {
        case enabled
        case disabled(reason: DisableReason)

        var allowTapHandling: Bool {
            switch self {
            case .enabled, .disabled(.cantStakeMore):
                true
            case .disabled(.insufficientFunds):
                false
            }
        }
    }
}

extension Period {
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .constant(let days):
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        case .variable(let min, let max):
            let minString = "\(min)"
            let maxString = formatter.string(from: DateComponents(day: max)) ?? max.formatted()
            return "\(minString) - \(maxString)"
        }
    }
}

private extension RewardClaimingType {
    var title: String {
        switch self {
        case .auto: Localization.stakingRewardClaimingAuto
        case .manual: Localization.stakingRewardClaimingManual
        }
    }
}

extension RewardScheduleType {
    func formatted() -> String {
        switch self {
        case .generic(let string):
            return string
        case .seconds(let min, let max):
            let prefix = Localization.stakingRewardScheduleEachPlural
            let suffix = Localization.commonSecondNoParam
            return "\(prefix) \(min)-\(max) \(suffix)"
        case .daily:
            return Localization.stakingRewardScheduleDay
        case .days(let min, let max):
            let prefix = Localization.stakingRewardScheduleEachPlural
            let suffix = Localization.commonDaysNoParam(max)
            return "\(prefix) \(min)-\(max) \(suffix)"
        }
    }
}

private extension RewardRateValues {
    func formatted(formatter: PercentFormatter) -> String {
        switch self {
        case .single(let value):
            formatter.format(value, option: .staking)
        case .interval(let min, let max):
            formatter.formatInterval(min: min, max: max)
        }
    }
}

private extension RewardType {
    var title: String {
        switch self {
        case .apr: Localization.stakingDetailsAnnualPercentageRate
        case .apy: Localization.stakingDetailsAnnualPercentageYield
        }
    }

    var info: String {
        switch self {
        case .apr: Localization.stakingDetailsAnnualPercentageRateInfo
        case .apy: Localization.stakingDetailsAnnualPercentageYieldInfo
        }
    }
}

extension StakingAction.ActionType {
    var title: String {
        switch self {
        case .stake, .pending(.stake): Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .pending(.withdraw): Localization.stakingWithdraw
        case .pending(.claimRewards): Localization.commonClaimRewards
        case .pending(.restakeRewards): Localization.stakingRestakeRewards
        case .pending(.voteLocked): Localization.stakingVote
        case .pending(.unlockLocked): Localization.stakingUnlockedLocked
        case .pending(.restake): Localization.stakingRestake
        case .pending(.claimUnstaked): Localization.stakingWithdraw
        }
    }
}

extension DateComponentsFormatter {
    static func staking() -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }
}
