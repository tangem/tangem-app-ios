//
//  StakingDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation
import TangemStaking

final class StakingDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { Localization.stakingDetailsTitle(wallet.name) }
    @Published var detailsViewModels: [DefaultRowViewModel] = []
    @Published var averageRewardingViewData: AverageRewardingViewData?
    @Published var rewardViewData: RewardViewData?

    // MARK: - Dependencies

    private let wallet: WalletModel
    private let manager: StakingManager
    private weak var coordinator: StakingDetailsRoutable?

    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter = PercentFormatter()
    private let daysFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }()

    init(
        wallet: WalletModel,
        manager: StakingManager,
        coordinator: StakingDetailsRoutable
    ) {
        self.wallet = wallet
        self.manager = manager
        self.coordinator = coordinator
    }

    func userDidTapBanner() {}
    func userDidTapActionButton() {}

    func onAppear() {
        runTask(in: self) { viewModel in
            let yield = try await viewModel.manager.getYield(item: viewModel.wallet.stakingTokenItem)
            await viewModel.setupView(yield: yield)
        }
    }
}

private extension StakingDetailsViewModel {
    @MainActor
    func setupView(yield: YieldInfo) {
        setupView(
            inputData: StakingDetailsData(
                available: 0,
                staked: 0,
                rewardType: yield.rewardType,
                rewardRate: yield.rewardRate,
                minimumRequirement: yield.minimumRequirement,
                warmupPeriod: yield.warmupPeriod,
                unbondingPeriod: yield.unbondingPeriod,
                rewardClaimingType: yield.rewardClaimingType,
                rewardScheduleType: yield.rewardScheduleType
            )
        )
    }

    func setupView(inputData: StakingDetailsData) {
        setupAverageRewardingViewData(inputData: inputData)
        setupDetailsSection(inputData: inputData)
    }

    func setupAverageRewardingViewData(inputData: StakingDetailsData) {
        // [REDACTED_TODO_COMMENT]

        let profitFormatted = balanceFormatter.formatFiatBalance(100)
        let days = 30
        let periodProfitFormatted = daysFormatter.string(from: DateComponents(day: days)) ?? days.formatted()

        averageRewardingViewData = .init(
            rewardType: inputData.rewardType.title,
            rewardFormatted: percentFormatter.percentFormat(value: inputData.rewardRate),
            periodProfitFormatted: periodProfitFormatted,
            profitFormatted: profitFormatted
        )
    }

    func setupDetailsSection(inputData: StakingDetailsData) {
        let availableFormatted = balanceFormatter.formatCryptoBalance(
            inputData.available,
            currencyCode: wallet.tokenItem.currencySymbol
        )

        let stakedFormatted = balanceFormatter.formatCryptoBalance(
            inputData.staked,
            currencyCode: wallet.tokenItem.currencySymbol
        )

        let rewardRateFormatted = percentFormatter.percentFormat(value: inputData.rewardRate)

        let unbondingFormatted = inputData.unbondingPeriod.formatted(formatter: daysFormatter)
        let minimumFormatted = balanceFormatter.formatCryptoBalance(
            inputData.minimumRequirement,
            currencyCode: wallet.tokenItem.currencySymbol
        )

        let warmupFormatted = inputData.warmupPeriod.formatted(formatter: daysFormatter)

        detailsViewModels = [
            DefaultRowViewModel(title: Localization.stakingDetailsAvailable, detailsType: .text(availableFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsOnStake, detailsType: .text(stakedFormatted)),
            DefaultRowViewModel(title: inputData.rewardType.title, detailsType: .text(rewardRateFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsUnbondingPeriod, detailsType: .text(unbondingFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsMinimumRequirement, detailsType: .text(minimumFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsRewardClaiming, detailsType: .text(inputData.rewardClaimingType.title)),
            DefaultRowViewModel(title: Localization.stakingDetailsWarmupPeriod, detailsType: .text(warmupFormatted)),
            DefaultRowViewModel(title: Localization.stakingDetailsRewardSchedule, detailsType: .text(inputData.rewardScheduleType.title)),
        ]
    }
}

extension StakingDetailsViewModel {
    struct StakingDetailsData {
        let available: Decimal
        let staked: Decimal
        let rewardType: RewardType
        let rewardRate: Decimal
        let minimumRequirement: Decimal
        let warmupPeriod: Period
        let unbondingPeriod: Period
        let rewardClaimingType: RewardClaimingType
        let rewardScheduleType: RewardScheduleType
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
        rawValue.uppercased()
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
