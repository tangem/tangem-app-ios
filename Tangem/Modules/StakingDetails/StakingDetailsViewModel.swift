//
//  StakingDetailsViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation
import TangemStaking

final class StakingDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { Localization.stakingDetailsTitle(walletModel.name) }
    @Published var displayHeaderView: Bool = false
    @Published var detailsViewModels: [DefaultRowViewModel] = []
    @Published var averageRewardingViewData: AverageRewardingViewData?
    @Published var rewardViewData: RewardViewData?
    @Published var validatorsViewData: ValidatorsViewData?
    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    // MARK: - Dependencies

    private let walletModel: WalletModel
    private let stakingManager: StakingManager
    private weak var coordinator: StakingDetailsRoutable?

    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter = PercentFormatter()
    private let daysFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }()

    private let _yieldInfo = CurrentValueSubject<LoadingValue<YieldInfo>, Never>(.loading)
    private let _balanceInfo = CurrentValueSubject<LoadingValue<StakingBalanceInfo>, Never>(.loading)

    private var bag: Set<AnyCancellable> = []

    init(
        walletModel: WalletModel,
        stakingManager: StakingManager,
        coordinator: StakingDetailsRoutable
    ) {
        self.walletModel = walletModel
        self.stakingManager = stakingManager
        self.coordinator = coordinator

        bind()
    }

    func userDidTapBanner() {}
    func userDidTapActionButton() {
        coordinator?.openStakingFlow()
    }

    func onAppear() {
        loadValues()
    }
}

private extension StakingDetailsViewModel {
    func loadValues() {
        Task {
            try await stakingManager.updateState()
        }
    }

    func bind() {
        stakingManager
            .statePublisher
            .compactMap { state -> ([StakingBalanceInfo]?, YieldInfo)? in
                switch state {
                case .loading: nil
                case .notEnabled: nil
                case .availableToStake(let yieldInfo): (nil, yieldInfo)
                case .staked(let stakingBalanceInfo, let yieldInfo): (stakingBalanceInfo, yieldInfo)
                }
            }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, args in
                viewModel.setupView(yield: args.1, balancesInfo: args.0)
            }
            .store(in: &bag)
    }

    func setupView(yield: YieldInfo, balancesInfo: [StakingBalanceInfo]?) {
        let maxBlockedBalance: Decimal = (balancesInfo ?? []).max(by: { $0.blocked > $1.blocked })?.blocked ?? .zero
        let available = walletModel.balanceValue ?? .zero - maxBlockedBalance
        let aprs = yield.validators.compactMap(\.apr)
        var validatorBalances: [ValidatorBalanceInfo] = []
        if let balancesInfo {
            validatorBalances = yield.validators.compactMap { validatorInfo -> ValidatorBalanceInfo? in
                guard let balanceInfo = balancesInfo.filter({ $0.validatorAddress == validatorInfo.address }).first else {
                    return nil
                }
                return ValidatorBalanceInfo(validator: validatorInfo, balance: balanceInfo.blocked)
            }
        }
        setupView(
            inputData: StakingDetailsData(
                available: available, // Maybe add skeleton?
                staked: maxBlockedBalance,
                rewards: Decimal(stringValue: "1"),
                rewardType: yield.rewardType,
                rewardRate: yield.rewardRate,
                rewardRateValues: RewardRateValues(aprs: aprs, rewardRate: yield.rewardRate),
                minimumRequirement: yield.minimumRequirement,
                warmupPeriod: yield.warmupPeriod,
                unbondingPeriod: yield.unbondingPeriod,
                rewardClaimingType: yield.rewardClaimingType,
                rewardScheduleType: yield.rewardScheduleType,
                validatorBalances: validatorBalances
            )
        )
    }

    func setupView(inputData: StakingDetailsData) {
        setupHeaderView(inputData: inputData)
        setupAverageRewardingViewData(inputData: inputData)
        setupDetailsSection(inputData: inputData)
        setupRewardView(inputData: inputData)
        setupValidatorsView(input: inputData)
    }

    func setupHeaderView(inputData: StakingDetailsData) {
        displayHeaderView = inputData.staked.isZero
    }

    func setupAverageRewardingViewData(inputData: StakingDetailsData) {
        let days = 30
        let periodProfitFormatted = daysFormatter.string(from: DateComponents(day: days)) ?? days.formatted()

        let profitFormatted = walletModel.balanceValue.map { balanceValue in
            let profit = StakingCalculator().earnValue(
                invest: balanceValue,
                apr: inputData.rewardRate,
                period: .days(days)
            )
            return balanceFormatter.formatFiatBalance(profit)
        }

        averageRewardingViewData = .init(
            rewardType: inputData.rewardType.title,
            rewardFormatted: inputData.rewardRateValues.formatted(formatter: percentFormatter),
            periodProfitFormatted: periodProfitFormatted,
            profitFormatted: profitFormatted.map { .loaded(text: $0) } ?? .noData
        )
    }

    func setupDetailsSection(inputData: StakingDetailsData) {
        let availableFormatted = balanceFormatter.formatCryptoBalance(
            inputData.available,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let stakedFormatted = balanceFormatter.formatCryptoBalance(
            inputData.staked,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let rewardRateFormatted = inputData.rewardRateValues.formatted(formatter: percentFormatter)

        let unbondingFormatted = inputData.unbondingPeriod.formatted(formatter: daysFormatter)
        let minimumFormatted = balanceFormatter.formatCryptoBalance(
            inputData.minimumRequirement,
            currencyCode: walletModel.tokenItem.currencySymbol
        )

        let warmupFormatted = inputData.warmupPeriod.formatted(formatter: daysFormatter)

        var rewardSecondaryAction: (() -> Void)?
        if let rewardTypeDescrption = inputData.rewardType.description {
            rewardSecondaryAction = { [weak self] in
                self?.openBottomSheet(title: inputData.rewardType.title, description: rewardTypeDescrption)
            }
        }

        detailsViewModels = [
            DefaultRowViewModel(title: Localization.stakingDetailsAvailable, detailsType: .text(availableFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsOnStake, detailsType: .text(stakedFormatted)),
            DefaultRowViewModel(
                title: inputData.rewardType.title,
                detailsType: .text(
                    rewardRateFormatted
                ),
                secondaryAction: rewardSecondaryAction
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsUnbondingPeriod,
                detailsType: .text(unbondingFormatted),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsUnbondingPeriod,
                    description: Localization.stakingDetailsUnbondingPeriodInfo
                ) }
            ),
            DefaultRowViewModel(title: Localization.stakingDetailsMinimumRequirement, detailsType: .text(minimumFormatted)),
            DefaultRowViewModel(
                title: Localization.stakingDetailsRewardClaiming,
                detailsType: .text(inputData.rewardClaimingType.title),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsRewardClaiming,
                    description: Localization.stakingDetailsRewardClaimingInfo
                ) }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsWarmupPeriod,
                detailsType: .text(warmupFormatted),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsWarmupPeriod,
                    description: Localization.stakingDetailsWarmupPeriodInfo
                ) }
            ),
            DefaultRowViewModel(
                title: Localization.stakingDetailsRewardSchedule,
                detailsType: .text(inputData.rewardScheduleType.title),
                secondaryAction: { [weak self] in self?.openBottomSheet(
                    title: Localization.stakingDetailsRewardSchedule,
                    description: Localization.stakingDetailsRewardScheduleInfo
                ) }
            ),
        ]
    }

    func setupRewardView(inputData: StakingDetailsData) {
        guard !inputData.staked.isZero else {
            rewardViewData = nil
            return
        }
        let state: RewardViewData.State
        if let rewards = inputData.rewards {
            let rewardsCryptoFormatted = balanceFormatter.formatCryptoBalance(
                rewards,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let rewardsFiat = walletModel.tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(rewards, currencyId: $0)
            }
            let rewardsFiatFormatted = balanceFormatter.formatFiatBalance(rewardsFiat)
            state = .rewards(fiatFormatted: rewardsFiatFormatted, cryptoFormatted: rewardsCryptoFormatted)
        } else {
            state = .noRewards
        }
        rewardViewData = RewardViewData(state: state)
    }

    func setupValidatorsView(input: StakingDetailsData) {
        let validators = input.validatorBalances.map { validatorBalance in
            let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
                validatorBalance.balance,
                currencyCode: walletModel.tokenItem.currencySymbol
            )
            let balanceFiat = walletModel.tokenItem.currencyId.flatMap {
                BalanceConverter().convertToFiat(validatorBalance.balance, currencyId: $0)
            }
            let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)
            return StakingValidatorViewMapper().mapToValidatorViewData(
                info: validatorBalance.validator,
                detailsType: .balance(crypto: balanceCryptoFormatted, fiat: balanceFiatFormatted)
            )
        }
        validatorsViewData = ValidatorsViewData(validators: validators)
    }

    func openBottomSheet(title: String, description: String) {
        descriptionBottomSheetInfo = DescriptionBottomSheetInfo(title: title, description: description)
    }
}

extension StakingDetailsViewModel {
    struct StakingDetailsData {
        let available: Decimal
        let staked: Decimal
        let rewards: Decimal?
        let rewardType: RewardType
        let rewardRate: Decimal
        let rewardRateValues: RewardRateValues
        let minimumRequirement: Decimal
        let warmupPeriod: Period
        let unbondingPeriod: Period
        let rewardClaimingType: RewardClaimingType
        let rewardScheduleType: RewardScheduleType
        let validatorBalances: [ValidatorBalanceInfo]
    }
}

private extension Period {
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        }
    }
}

private extension DateComponentsFormatter {
    func formatted(days: Int) -> String {
        return string(from: DateComponents(day: days)) ?? days.formatted()
    }
}

private extension RewardType {
    var title: String {
        switch self {
        case .apr:
            Localization.stakingDetailsApr
        case .apy:
            Localization.stakingDetailsApy
        case .variable:
            rawValue.uppercased()
        }
    }

    var description: String? {
        guard case .apy = self else {
            return nil
        }
        return Localization.stakingDetailsApyInfo
    }
}

private extension RewardClaimingType {
    var title: String {
        rawValue.capitalizingFirstLetter()
    }
}

private extension RewardScheduleType {
    var title: String {
        rawValue.capitalizingFirstLetter()
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
