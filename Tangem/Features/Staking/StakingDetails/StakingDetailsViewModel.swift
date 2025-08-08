//
//  StakingDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemStaking
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers
import struct TangemUIUtils.ActionSheetBinder
import struct TangemUIUtils.AlertBinder

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
    @Published var actionSheet: ActionSheetBinder?
    @Published var alert: AlertBinder?

    lazy var legalText = makeLegalText()

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let tokenBalanceProvider: TokenBalanceProvider
    private let stakingManager: StakingManager
    private let accountInitializedStateProvider: StakingAccountInitializationStateProvider?
    private weak var coordinator: StakingDetailsRoutable?

    private var isAccountInitialized = true

    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var percentFormatter = PercentFormatter()
    private lazy var dateFormatter = DateComponentsFormatter.staking()
    private lazy var stakesBuilder = StakingDetailsStakeViewDataBuilder(tokenItem: tokenItem)

    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        tokenBalanceProvider: TokenBalanceProvider,
        stakingManager: StakingManager,
        coordinator: StakingDetailsRoutable,
        accountInitializedStateProvider: StakingAccountInitializationStateProvider?
    ) {
        self.tokenItem = tokenItem
        self.tokenBalanceProvider = tokenBalanceProvider
        self.stakingManager = stakingManager
        self.coordinator = coordinator
        self.accountInitializedStateProvider = accountInitializedStateProvider

        bind()
    }

    func refresh(completion: @escaping () -> Void = {}) {
        runTask(in: self) { viewModel in
            async let updateState: Void = viewModel.stakingManager.updateState(loadActions: true)

            guard let accountInitializedStateProvider = viewModel.accountInitializedStateProvider else {
                await updateState
                completion()
                return
            }

            async let isAccountInitialized = try? await accountInitializedStateProvider.isAccountInitialized()
            let result = await (isAccountInitialized, updateState)

            viewModel.isAccountInitialized = result.0 ?? true

            completion()
        }
    }

    func userDidTapBanner() {
        coordinator?.openWhatIsStaking()
    }

    func userDidTapActionButton() {
        if case .ton = tokenItem.blockchain, !isAccountInitialized {
            alert = .init(
                title: Localization.commonAttention,
                message: Localization.stakingNotificationTonActivateAccount
            )
            return
        }

        guard stakingManager.state.yieldInfo?.preferredValidators.allSatisfy({ $0.status == .full }) == false else {
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

        guard stakingManager.state.yieldInfo?.preferredValidators.isEmpty == false else {
            alert = .init(title: Localization.commonWarning, message: Localization.stakingNoValidatorsErrorMessage)
            return
        }

        coordinator?.openStakingFlow()
    }

    func onAppear() {
        refresh()
        let balances = stakingManager.balances.flatMap { String($0.count) } ?? String(0)
        Analytics.log(
            event: .stakingInfoScreenOpened,
            params: [
                .validatorsCount: balances,
                .token: tokenItem.currencySymbol,
            ]
        )
    }
}

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

    func setupView(yield: YieldInfo, balances: [StakingBalance]) {
        setupHeaderView(hasBalances: !balances.isEmpty)
        setupDetailsSection(yield: yield)
        setupStakes(yield: yield, staking: balances.stakes())
        setupRewardView(yield: yield, balances: balances)
    }

    func setupHeaderView(hasBalances: Bool) {
        hideStakingInfoBanner = hasBalances
    }

    func setupDetailsSection(yield: YieldInfo) {
        var viewModels = [
            DefaultRowViewModel(
                title: Localization.stakingDetailsAnnualPercentageRate,
                detailsType: .text(yield.rewardRateValues.formatted(formatter: percentFormatter)),
                accessibilityIdentifier: StakingAccessibilityIdentifiers.annualPercentageRateValue,
                secondaryAction: { [weak self] in
                    self?.openBottomSheet(
                        title: Localization.stakingDetailsAnnualPercentageRate,
                        description: Localization.stakingDetailsAnnualPercentageRateInfo
                    )
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

    func setupRewardView(yield: YieldInfo, balances: [StakingBalance]) {
        guard !balances.isEmpty else {
            rewardViewData = nil
            return
        }

        let rewards = balances.rewards()
        switch rewards.sum() {
        case .zero where yield.rewardClaimingType == .auto:
            rewardViewData = RewardViewData(state: .automaticRewards)
        case .zero:
            rewardViewData = RewardViewData(state: .noRewards)
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
                }
            )
        }
    }

    func setupStakes(yield: YieldInfo, staking: [StakingBalance]) {
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
                self?.openFlow(balance: balance, validators: yield.validators)
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

    func openFlow(balance: StakingBalance, validators: [ValidatorInfo]) {
        do {
            let action = try PendingActionMapper(balance: balance, validators: validators).getAction()
            switch action {
            case .single(let action):
                openFlow(for: action)
            case .multiple(let actions):
                var buttons: [Alert.Button] = actions.map { action in
                    .default(Text(action.displayType.title)) { [weak self] in
                        self?.openFlow(for: action)
                    }
                }

                buttons.append(.cancel())
                actionSheet = .init(sheet: .init(title: Text(Localization.commonSelectAction), buttons: buttons))
            }
        } catch {
            alert = AlertBuilder.makeOkErrorAlert(message: error.localizedDescription)
        }
    }

    private func openRewardsFlow(rewardsBalances: [StakingBalance], yield: YieldInfo) {
        if rewardsBalances.count == 1, let rewardsBalance = rewardsBalances.first {
            openFlow(balance: rewardsBalance, validators: yield.validators)

            let name = rewardsBalance.validatorType.validator?.name
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
        yield: YieldInfo,
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

        alert = AlertBuilder.makeAlert(
            title: "",
            message: Localization.stakingDetailsMinRewardsNotification(yield.item.name, minAmountString),
            primaryButton: .default(Text(Localization.warningButtonOk), action: {})
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
        formatLink(in: &attributedString, textToSearch: tos, url: Constants.tosURL)
        formatLink(in: &attributedString, textToSearch: policy, url: Constants.privacyPolicyURL)
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
    }
}

extension Period {
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
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
            formatter.formatInterval(min: min, max: max, option: .staking)
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

extension StakingDetailsViewModel {
    enum Constants {
        static let tosURL = URL(string: "https://docs.stakek.it/docs/terms-of-use")!
        static let privacyPolicyURL = URL(string: "https://docs.stakek.it/docs/privacy-policy")!
    }
}
