//
//  YieldModuleClaimViewDataMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemLocalization

struct YieldModuleClaimViewDataMapper {
    private let blockchain: Blockchain
    private let storage: YieldModuleClaimViewData.Storage?

    private let iconInfoBuilder = TokenIconInfoBuilder()
    private let amountFormatter = YieldIncentiveAmountFormatter()
    private let balanceFormatter = BalanceFormatter()

    init(blockchain: Blockchain, storage: YieldModuleClaimViewData.Storage?) {
        self.blockchain = blockchain
        self.storage = storage
    }

    func map(summary: YieldIncentivesRewardsSummary) -> YieldModuleClaimViewData {
        let claimableRewards = summary.claimableRewards

        var sections = Constants.claimableDestinationsOrder.compactMap { destination -> YieldModuleClaimViewData.Section? in
            let rewards = claimableRewards.filter { $0.destination == destination }

            guard !rewards.isEmpty else {
                return nil
            }

            return YieldModuleClaimViewData.Section(
                id: destination.rawValue,
                title: title(for: destination),
                storage: destination == .owner ? storage : nil,
                rewards: rewards.map(makeClaimableReward)
            )
        }

        let unclaimableRewards = summary.rewards.filter { !$0.isSupported && $0.claimableAmount > 0 }

        if !unclaimableRewards.isEmpty {
            sections.append(
                YieldModuleClaimViewData.Section(
                    id: YieldIncentiveReward.Destination.unsupported.rawValue,
                    title: title(for: .unsupported),
                    storage: nil,
                    rewards: unclaimableRewards.map(makeUnclaimableReward)
                )
            )
        }

        let data = YieldModuleClaimViewData(
            total: balanceFormatter.formatFiatBalance(summary.totalClaimableNetUsd, currencyCode: AppConstants.usdCurrencyCode),
            sections: sections
        )

        return data
    }

    func mapSuccess(summary: YieldIncentivesRewardsSummary) -> YieldModuleClaimSuccessViewData {
        YieldModuleClaimSuccessViewData(
            total: balanceFormatter.formatFiatBalance(summary.totalClaimableNetUsd, currencyCode: AppConstants.usdCurrencyCode)
        )
    }

    func mapServiceFee(amountUsd: Decimal, summary: YieldIncentivesRewardsSummary) -> String {
        let amount = balanceFormatter.formatFiatBalance(amountUsd, currencyCode: AppConstants.usdCurrencyCode)

        guard let rate = serviceFeeRate(for: summary) else {
            return amount
        }

        return Constants.serviceFeeFormat(rate, amount)
    }

    private func serviceFeeRate(for summary: YieldIncentivesRewardsSummary) -> String? {
        let rates = Set(summary.claimableRewards.map(\.serviceFeeRateBps))

        // A single shared rate is the only one that can be stated for the claim as a whole.
        guard rates.count == 1, let rateBps = rates.first else {
            return nil
        }

        return PercentFormatter().format(Decimal(rateBps) / Constants.bpsInWhole, option: .yieldServiceFee)
    }

    private func title(for destination: YieldIncentiveReward.Destination) -> String {
        switch destination {
        case .owner:
            return Localization.yieldModuleClaimDestinationOwnerTitle
        case .aave:
            return Localization.yieldModuleClaimDestinationAaveTitle
        case .module:
            return Localization.yieldModuleClaimDestinationModuleTitle
        case .unsupported:
            return Localization.yieldModuleClaimDestinationUnsupportedTitle
        }
    }

    private func makeClaimableReward(_ reward: YieldIncentiveReward) -> YieldModuleClaimViewData.Reward {
        makeReward(
            reward,
            amount: reward.estimatedNetClaimableAmount,
            fiatAmount: balanceFormatter.formatFiatBalance(reward.estimatedNetValueUsd, currencyCode: AppConstants.usdCurrencyCode)
        )
    }

    private func makeUnclaimableReward(_ reward: YieldIncentiveReward) -> YieldModuleClaimViewData.Reward {
        makeReward(reward, amount: reward.claimableAmount, fiatAmount: nil)
    }

    private func makeReward(
        _ reward: YieldIncentiveReward,
        amount: BigUInt,
        fiatAmount: String?
    ) -> YieldModuleClaimViewData.Reward {
        let token = Token(
            name: reward.symbol,
            symbol: reward.symbol,
            contractAddress: reward.rewardTokenAddress,
            decimalCount: reward.decimals
        )

        return YieldModuleClaimViewData.Reward(
            id: reward.rewardTokenAddress,
            iconInfo: iconInfoBuilder.build(for: .token(value: token), in: blockchain, isCustom: false),
            symbol: reward.symbol,
            networkName: blockchain.displayName,
            amount: amountFormatter.format(baseUnits: amount, decimals: reward.decimals, symbol: reward.symbol)
                ?? AppConstants.emDashSign,
            fiatAmount: fiatAmount
        )
    }
}

// MARK: - Constants

private extension YieldModuleClaimViewDataMapper {
    enum Constants {
        static let claimableDestinationsOrder: [YieldIncentiveReward.Destination] = [.owner, .aave, .module]
        static let bpsInWhole: Decimal = 10_000

        static func serviceFeeFormat(_ rate: String, _ amount: String) -> String {
            "(\(rate)) \(amount)"
        }
    }
}
