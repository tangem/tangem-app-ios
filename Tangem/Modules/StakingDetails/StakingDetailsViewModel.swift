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

    @Published var detailsViewModels: [DefaultRowViewModel] = []
    @Published var averageRewardingViewData: AverageRewardingViewData?
    @Published var rewardViewData: RewardViewData?

    // MARK: - Dependencies

    private let inputData: StakingDetailsData
    private weak var coordinator: StakingDetailsRoutable?
    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter = PercentFormatter()
    private let dateComponentsFormatter = DateComponentsFormatter()

    init(
        inputData: StakingDetailsData,
        coordinator: StakingDetailsRoutable
    ) {
        self.inputData = inputData
        self.coordinator = coordinator

        setupAverageRewardingViewData()
        setupDetailsSection()
        setupRewardViewData()
    }

    func userDidTapBanner() {}
}

private extension StakingDetailsViewModel {
    func aprFormatted() -> String {
        let minAPRFormatted = percentFormatter.percentFormat(value: inputData.minAPR)
        let maxAPRFormatted = percentFormatter.percentFormat(value: inputData.maxAPR)
        let aprFormatted = "\(minAPRFormatted) - \(maxAPRFormatted)"
        return aprFormatted
    }

    func setupAverageRewardingViewData() {
        let profitFormatted = balanceFormatter.formatFiatBalance(inputData.monthEstimatedProfit)
        averageRewardingViewData = .init(
            aprFormatted: aprFormatted(),
            profitFormatted: profitFormatted
        )
    }

    func setupRewardViewData() {
        let fiatFormatted = balanceFormatter.formatFiatBalance(inputData.monthEstimatedProfit)
        let cryptoFormatted = balanceFormatter.formatCryptoBalance(
            inputData.staked,
            currencyCode: inputData.tokenItem.currencySymbol
        )

        rewardViewData = .init(state: .rewards(fiatFormatted: fiatFormatted, cryptoFormatted: cryptoFormatted))
    }

    func setupDetailsSection() {
        let availableFormatted = balanceFormatter.formatCryptoBalance(
            inputData.available,
            currencyCode: inputData.tokenItem.currencySymbol
        )

        let stakedFormatted = balanceFormatter.formatCryptoBalance(
            inputData.staked,
            currencyCode: inputData.tokenItem.currencySymbol
        )

        let unbondingFormatted = inputData.unbonding.formatted(formatter: dateComponentsFormatter)
        let minimumFormatted = balanceFormatter.formatCryptoBalance(
            inputData.minimumRequirement,
            currencyCode: inputData.tokenItem.currencySymbol
        )

        let warmupFormatted = inputData.warmupPeriod.formatted(formatter: dateComponentsFormatter)

        detailsViewModels = [
            DefaultRowViewModel(title: "Available", detailsType: .text(availableFormatted)),
            DefaultRowViewModel(title: "On stake", detailsType: .text(stakedFormatted)),
            DefaultRowViewModel(title: "APR", detailsType: .text(aprFormatted())),
            DefaultRowViewModel(title: "Unbonding Period", detailsType: .text(unbondingFormatted)),
            DefaultRowViewModel(title: "Minimum Requirement", detailsType: .text(minimumFormatted)),
            DefaultRowViewModel(title: "Reward claiming", detailsType: .text(inputData.rewardClaimingType.title)),
            DefaultRowViewModel(title: "Warmup period", detailsType: .text(warmupFormatted)),
            DefaultRowViewModel(title: "Reward schedule", detailsType: .text(inputData.rewardScheduleType.title)),
        ]
    }
}

struct StakingDetailsData {
    let tokenItem: TokenItem
    let monthEstimatedProfit: Decimal
    let available: Decimal
    let staked: Decimal
    let minAPR: Decimal
    let maxAPR: Decimal
    let unbonding: Period
    let minimumRequirement: Decimal
    let rewardClaimingType: RewardClaimingType
    let warmupPeriod: Period
    let rewardScheduleType: RewardScheduleType
}

private extension Period {
    func formatted(formatter: DateComponentsFormatter) -> String {
        switch self {
        case .days(let days):
            formatter.unitsStyle = .short
            formatter.allowedUnits = [.day]
            return formatter.string(from: DateComponents(day: days)) ?? days.formatted()
        }
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
