//
//  StakeDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation

final class StakeDetailsViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var detailsViewModels: [DefaultRowViewModel] = []

    // MARK: - Dependencies

    private let inputData: StakeDetailsData
    private weak var coordinator: StakeDetailsRoutable?
    private let balanceFormatter = BalanceFormatter()
    private let percentFormatter = PercentFormatter()
    private let dateFormatter = DateFormatter(dateFormat: "DD")

    init(
        inputData: StakeDetailsData,
        coordinator: StakeDetailsRoutable
    ) {
        self.inputData = inputData
        self.coordinator = coordinator

        setupDetailsSection()
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

        let minAPRFormatted = percentFormatter.percentFormat(value: inputData.minAPR)
        let maxAPRFormatted = percentFormatter.percentFormat(value: inputData.maxAPR)
        let aprFormatted = "\(minAPRFormatted) \(AppConstants.dashSign) \(maxAPRFormatted)"

        let unbondingFormatted = dateFormatter.string(from: inputData.unbonding)
        let minimumFormatted = balanceFormatter.formatCryptoBalance(
            inputData.minimumRequirement,
            currencyCode: inputData.tokenItem.currencySymbol
        )

        let warmupFormatted = dateFormatter.string(from: inputData.warmupPeriod)

        detailsViewModels = [
            DefaultRowViewModel(title: "Available", detailsType: .text(availableFormatted)),
            DefaultRowViewModel(title: "On stake", detailsType: .text(stakedFormatted)),
            DefaultRowViewModel(title: "APR", detailsType: .text(aprFormatted)),
            DefaultRowViewModel(title: "Unbonding Period", detailsType: .text(unbondingFormatted)),
            DefaultRowViewModel(title: "Minimum Requirement", detailsType: .text(minimumFormatted)),
            DefaultRowViewModel(title: "Reward claiming", detailsType: .text(inputData.rewardClaimingType.title)),
            DefaultRowViewModel(title: "Warmup period", detailsType: .text(warmupFormatted)),
            DefaultRowViewModel(title: "Reward schedule", detailsType: .text(inputData.rewardScheduleType.title)),
        ]
    }
}

struct StakeDetailsData {
    let tokenItem: TokenItem
    let monthEstimatedProfit: String
    let available: Decimal
    let staked: Decimal
    let minAPR: Decimal
    let maxAPR: Decimal
    let unbonding: Date
    let minimumRequirement: Decimal
    let rewardClaimingType: RewardClaimingType
    let warmupPeriod: Date
    let rewardScheduleType: RewardScheduleType
}

enum RewardClaimingType: String, Hashable {
    case auto
    case manual

    var title: String {
        rawValue.capitalizingFirstLetter()
    }
}

enum RewardScheduleType: String, Hashable {
    case block

    var title: String {
        rawValue.capitalizingFirstLetter()
    }
}
