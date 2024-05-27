//
//  StakekitMapper.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakekitMapper {
    func mapToYieldInfo(from response: StakekitDTO.Yield.Info.Response) throws -> YieldInfo {
        guard let enterAction = response.args.enter else {
            throw StakekitMapperError.noData("EnterAction not found")
        }

        return try YieldInfo(
            item: mapToStakingTokenItem(from: response.token),
            apy: response.apy,
            rewardRate: response.rewardRate,
            rewardType: mapToRewardType(from: response.rewardType),
            unbonding: mapToPeriod(from: response.metadata.cooldownPeriod),
            minimumRequirement: enterAction.args.amount.minimum,
            rewardClaimingType: mapToRewardClaimingType(from: response.metadata.rewardClaiming),
            warmupPeriod: mapToPeriod(from: response.metadata.warmupPeriod),
            rewardScheduleType: mapToRewardScheduleType(from: response.metadata.rewardSchedule)
        )
    }

    // MARK: - Inner types

    func mapToStakingTokenItem(from token: StakekitDTO.Token) -> StakingTokenItem {
        StakingTokenItem(network: token.network, contractAdress: token.address)
    }

    func mapToRewardType(from rewardType: StakekitDTO.Yield.Info.Response.RewardType) -> RewardType {
        switch rewardType {
        case .apr: .apr
        case .apy: .apy
        case .variable: .variable
        }
    }

    func mapToPeriod(from period: StakekitDTO.Yield.Info.Response.Metadata.Period) -> Period {
        .days(period.days)
    }

    func mapToRewardClaimingType(from type: StakekitDTO.Yield.Info.Response.Metadata.RewardClaiming) -> RewardClaimingType {
        switch type {
        case .auto: .auto
        case .manual: .manual
        }
    }

    func mapToRewardScheduleType(from type: StakekitDTO.Yield.Info.Response.Metadata.RewardScheduleType) throws -> RewardScheduleType {
        switch type {
        case .block: .block
        case .hour: .hour
        case .day: .day
        case .week: .week
        case .month: .month
        case .era: .era
        case .epoch: .epoch
        }
    }
}

enum StakekitMapperError: Error {
    case notImplement
    case noData(String)
}
