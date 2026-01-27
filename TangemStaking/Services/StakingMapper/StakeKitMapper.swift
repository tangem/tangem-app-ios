//
//  StakeKitMapper.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakeKitMapper {
    // MARK: - To DTO

    func mapToEnterRequest(request: ActionGenericRequest) -> StakeKitDTO.EstimateGas.Enter.Request {
        StakeKitDTO.EstimateGas.Enter.Request(
            integrationId: request.integrationId,
            addresses: mapToAddress(request: request),
            args: mapToActionsArgs(request: request)
        )
    }

    func mapToExitRequest(request: ActionGenericRequest) -> StakeKitDTO.EstimateGas.Exit.Request {
        StakeKitDTO.EstimateGas.Exit.Request(
            integrationId: request.integrationId,
            addresses: mapToAddress(request: request),
            args: mapToActionsArgs(request: request)
        )
    }

    func mapToPendingRequest(request: PendingActionRequest) -> StakeKitDTO.EstimateGas.Pending.Request {
        StakeKitDTO.EstimateGas.Pending.Request(
            type: mapToActionType(from: request.type),
            integrationId: request.request.integrationId,
            passthrough: request.passthrough,
            addresses: mapToAddress(request: request.request),
            args: mapToActionsArgs(request: request.request)
        )
    }

    func mapToAddress(request: ActionGenericRequest) -> StakeKitDTO.Address {
        StakeKitDTO.Address(
            address: request.address,
            additionalAddresses: request.additionalAddresses.flatMap {
                StakeKitDTO.Address.AdditionalAddresses(cosmosPubKey: $0.cosmosPubKey)
            }
        )
    }

    func mapToActionsArgs(request: ActionGenericRequest) -> StakeKitDTO.Actions.Args {
        StakeKitDTO.Actions.Args(
            amount: request.amount.description,
            validatorAddress: request.target,
            validatorAddresses: request.target.map { [$0] },
            inputToken: mapToTokenDTO(from: request.token),
            tronResource: request.tronResource
        )
    }

    func mapToActionType(from action: StakingAction.PendingActionType) -> StakeKitDTO.Actions.ActionType {
        switch action {
        case .withdraw: .withdraw
        case .claimRewards: .claimRewards
        case .restakeRewards: .restakeRewards
        case .voteLocked: .voteLocked
        case .unlockLocked: .unlockLocked
        case .restake: .restake
        case .claimUnstaked: .claimUnstaked
        case .stake: .stake
        }
    }

    func mapToTokenDTO(from tokenItem: StakingTokenItem) -> StakeKitDTO.Token {
        StakeKitDTO.Token(
            network: tokenItem.network.asStakeKitNetworkType.rawValue,
            name: tokenItem.name,
            decimals: tokenItem.decimals,
            address: tokenItem.contractAddress,
            symbol: tokenItem.symbol
        )
    }

    // MARK: - Actions

    func mapToEnterAction(from response: StakeKitDTO.Actions.Enter.Response) throws -> EnterAction {
        guard let transactions = response.transactions?.filter({ $0.status != .skipped }),
              !transactions.isEmpty else {
            throw StakeKitMapperError.noData("EnterAction.transactions not found")
        }

        guard let amount = Decimal(string: response.amount) else {
            throw StakeKitMapperError.noData("EnterAction.amount not found")
        }

        let actionTransaction: [ActionTransaction] = transactions.map { transaction in
            ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
        }

        return try EnterAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            amount: amount,
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    func mapToExitAction(from response: StakeKitDTO.Actions.Exit.Response) throws -> ExitAction {
        guard let transactions = response.transactions?.filter({ $0.status != .skipped }),
              !transactions.isEmpty else {
            throw StakeKitMapperError.noData("ExitAction.transactions not found")
        }

        guard let amount = Decimal(string: response.amount) else {
            throw StakeKitMapperError.noData("ExitAction.amount not found")
        }

        let actionTransaction: [ActionTransaction] = transactions.map { transaction in
            ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
        }

        return try ExitAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            amount: amount,
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction
        )
    }

    func mapToPendingActions(from response: StakeKitDTO.Actions.List.Response) throws -> [PendingAction] {
        try response.data.compactMap { action in
            guard let amountString = action.amount, let amount = Decimal(string: amountString) else {
                throw StakeKitMapperError.noData("PendingAction.amount not found")
            }

            // just to make sure zero or negative amount will not be displayed on UI
            guard amount > 0 else { return nil }

            let actionTransaction: [ActionTransaction] = action.transactions.map { transaction in
                ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
            }

            return try PendingAction(
                id: action.id,
                accountAddresses: action.accountAddresses,
                status: mapToActionStatus(from: action.status),
                amount: amount,
                type: mapToActionType(from: action.type),
                currentStepIndex: action.currentStepIndex,
                transactions: actionTransaction,
                targetAddress: action.validatorAddress ?? action.validatorAddresses?.first
            )
        }
    }

    func mapToPendingAction(from response: StakeKitDTO.Actions.Pending.Response) throws -> PendingAction {
        guard let transactions = response.transactions?.filter({ $0.status != .skipped }),
              !transactions.isEmpty else {
            throw StakeKitMapperError.noData("PendingAction.transactions not found")
        }

        guard let amount = Decimal(string: response.amount) else {
            throw StakeKitMapperError.noData("PendingAction.amount not found")
        }

        let actionTransaction: [ActionTransaction] = transactions.map { transaction in
            ActionTransaction(id: transaction.id, stepIndex: transaction.stepIndex)
        }

        return try PendingAction(
            id: response.id,
            status: mapToActionStatus(from: response.status),
            amount: amount,
            type: mapToActionType(from: response.type),
            currentStepIndex: response.currentStepIndex,
            transactions: actionTransaction,
            targetAddress: response.validatorAddress ?? response.validatorAddresses?.first
        )
    }

    // MARK: - Transaction

    func mapToTransactionInfo(from response: StakeKitDTO.Transaction.Response) throws -> StakingTransactionInfo {
        guard let unsignedTransaction = response.unsignedTransaction else {
            throw StakeKitMapperError.noData("Transaction.unsignedTransaction not found")
        }

        guard let fee = response.gasEstimate.flatMap({ Decimal(stringValue: $0.amount) }) else {
            throw StakeKitMapperError.noData("Transaction.gasEstimate not found")
        }

        guard let stakeId = response.stakeId else {
            throw StakeKitMapperError.noData("Transaction.stakeId not found")
        }

        let metadata = StakeKitTransactionMetadata(
            id: response.id,
            actionId: stakeId,
            type: response.type.rawValue,
            status: response.status.rawValue,
            stepIndex: response.stepIndex
        )

        return try StakingTransactionInfo(
            network: response.network.rawValue,
            unsignedTransactionData: .raw(mapToTransactionUnsignedData(from: unsignedTransaction, network: response.network)),
            fee: fee,
            metadata: metadata
        )
    }

    // MARK: - Balance

    func mapToBalanceInfo(from response: [StakeKitDTO.Balances.Response]) throws -> [StakingBalanceInfo] {
        guard let balances = response.first?.balances else {
            return []
        }

        return try balances.compactMap { balance in
            guard var amount = Decimal(stringValue: balance.amount) else {
                return nil
            }

            let stakingTokenItem = try mapToStakingTokenItem(from: balance.token)

            // for cardano rewards for some reason are included in balances
            // (e.g. staked balance == amount user staked initially + rewards amount
            // so we need to subtract the amount of rewards from balances to display them
            // consistently with the other network's balances
            if stakingTokenItem.rewardsIncludedInBalance, balance.type != .rewards {
                amount -= balances
                    .filter { $0.type == .rewards }
                    .compactMap { Decimal(stringValue: $0.amount) }
                    .sum()
            }

            // For Polygon token we can receive a staking balance with zero amount
            guard amount > 0 else {
                return nil
            }

            return try StakingBalanceInfo(
                item: stakingTokenItem,
                amount: amount,
                accountAddress: balance.accountAddress,
                balanceType: mapToBalanceType(from: balance),
                targetAddress: balance.validatorAddress ?? balance.validatorAddresses?.first,
                actions: mapToStakingBalanceInfoPendingAction(from: balance),
                actionConstraints: mapToBalanceConstraints(from: balance.pendingActionConstraints)
            )
        }
    }

    func mapToStakingBalanceInfoPendingAction(
        from balance: StakeKitDTO.Balances.Response.Balance
    ) throws -> [StakingPendingActionInfo] {
        try balance.pendingActions.compactMap { action in
            StakingPendingActionInfo(
                type: try mapToActionType(from: action.type),
                passthrough: action.passthrough
            )
        }
    }

    func mapToActionType(
        from actionType: StakeKitDTO.Actions.ActionType
    ) throws -> StakingPendingActionInfo.ActionType {
        switch actionType {
        case .stake: .stake
        case .vote: .vote
        case .unstake: .unstake
        case .withdraw: .withdraw
        case .claimRewards: .claimRewards
        case .restakeRewards: .restakeRewards
        case .voteLocked, .revote: .voteLocked
        case .unlockLocked: .unlockLocked
        case .restake: .restake
        case .claimUnstaked: .claimUnstaked
        default: throw StakeKitMapperError.noData("PendingAction.type \(actionType) doesn't supported")
        }
    }

    func mapToBalanceType(
        from balance: StakeKitDTO.Balances.Response.Balance
    ) throws -> StakingBalanceType {
        switch balance.type {
        case .available:
            throw StakeKitMapperError.notImplement
        case .locked:
            return .locked
        case .preparing:
            return .warmup
        case .staked:
            return .active
        case .unstaking, .unlocking:
            return .unbonding(date: balance.date)
        case .unstaked:
            return .unstaked
        case .rewards:
            return .rewards
        }
    }

    func mapToBalanceConstraints(
        from balanceConstraints: [StakeKitDTO.Balances.Response.Balance.PendingActionConstant]?
    ) throws -> [StakingPendingActionConstraint]? {
        try balanceConstraints?.map {
            StakingPendingActionConstraint(
                type: try mapToActionType(from: $0.type),
                amount: .init(minimum: $0.amount.minimum, maximum: $0.amount.maximum)
            )
        }
    }

    // MARK: - Yield

    func mapToYieldInfo(from response: StakeKitDTO.Yield.Info.Response) throws -> StakingYieldInfo {
        guard let enterAction = response.args.enter,
              let exitAction = response.args.exit else {
            throw StakeKitMapperError.noData("Enter or exit action is not found")
        }

        let item = try mapToStakingTokenItem(from: response.token)
        let rewardType = try mapToRewardType(rewardType: response.rewardType)
        let targets = response.validators.map { mapToStakingTargetInfo(from: $0, rewardType: rewardType) }
        let preferredTargets = targets.filter { $0.preferred }.sorted { lhs, rhs in
            if lhs.partner {
                return true
            }

            if rhs.partner {
                return false
            }

            return lhs.rewardRate > rhs.rewardRate
        }

        let rewardRateValues = RewardRateValues(
            aprs: preferredTargets.compactMap(\.rewardRate),
            rewardRate: response.rewardRate
        )

        return try StakingYieldInfo(
            id: response.id,
            isAvailable: response.isAvailable,
            rewardType: rewardType,
            rewardRateValues: rewardRateValues,
            enterMinimumRequirement: enterAction.args.amount.minimum ?? .zero,
            exitMinimumRequirement: exitAction.args.amount.minimum ?? .zero,
            targets: targets,
            preferredTargets: preferredTargets,
            item: item,
            unbondingPeriod: mapToPeriod(from: response.metadata.cooldownPeriod),
            warmupPeriod: mapToPeriod(from: response.metadata.warmupPeriod),
            rewardClaimingType: mapToRewardClaimingType(from: response.metadata.rewardClaiming),
            rewardScheduleType: mapToRewardScheduleType(from: response.metadata.rewardSchedule, item: item),
            maximumStakeAmount: nil
        )
    }

    // MARK: - Validators

    func mapToStakingTargetInfo(from validator: StakeKitDTO.Validator, rewardType: RewardType) -> StakingTargetInfo {
        StakingTargetInfo(
            address: validator.address,
            name: validator.name ?? "No name",
            preferred: validator.preferred ?? false,
            partner: validator.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == StakingConstants.partnerName,
            iconURL: validator.image.flatMap { URL(string: $0) },
            rewardType: rewardType,
            rewardRate: mapToRewardRate(validator: validator),
            status: mapToValidatorStatus(validator.status)
        )
    }

    private func mapToRewardRate(validator: StakeKitDTO.Validator) -> Decimal {
        guard let apr = validator.apr else {
            return 0
        }

        let commission = validator.commission ?? 0
        let rewardRate = apr / (1 - commission)
        return rewardRate
    }

    private func mapToValidatorStatus(_ status: StakeKitDTO.Validator.Status) -> StakingTargetInfoStatus {
        switch status {
        case .active: .active
        case .jailed: .jailed
        case .deactivating: .deactivating
        case .inactive: .inactive
        case .full: .full
        }
    }

    // MARK: - Inner types

    func mapToTransactionUnsignedData(from unsignedData: String, network: StakeKitNetworkType) throws -> String {
        switch network {
        case .tron:
            guard let data = unsignedData.data(using: .utf8) else {
                throw StakeKitMapperError.tronTransactionMappingFailed
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let tronTransaction = try decoder.decode(StakeKitDTO.Transaction.TronTransaction.self, from: data)
            return tronTransaction.rawDataHex
        default:
            return unsignedData
        }
    }

    func mapToActionStatus(from status: StakeKitDTO.Actions.ActionStatus) throws -> ActionStatus {
        switch status {
        case .created: .created
        case .waitingForNext: .waitingForNext
        case .processing: .processing
        case .failed: .failed
        case .success: .success
        case .canceled:
            throw StakeKitMapperError.notImplement
        }
    }

    func mapToStakingTokenItem(from token: StakeKitDTO.Token) throws -> StakingTokenItem {
        guard let stakeKitNetwork = StakeKitNetworkType(rawValue: token.network),
              let stakingNetwork = StakingNetworkType(stakeKitNetworkType: stakeKitNetwork) else {
            throw StakeKitMapperError.noData("StakingNetworkType not found")
        }

        return StakingTokenItem(
            network: stakingNetwork,
            contractAddress: token.address,
            name: token.name,
            decimals: token.decimals,
            symbol: token.symbol
        )
    }

    private func mapToRewardType(rewardType: StakeKitDTO.Yield.Info.Response.RewardType) throws -> RewardType {
        switch rewardType {
        case .apr: .apr
        case .apy: .apy
        case .variable:
            throw StakeKitMapperError.notImplement
        }
    }

    func mapToPeriod(from period: StakeKitDTO.Yield.Info.Response.Metadata.Period) -> Period {
        .constant(days: period.days)
    }

    func mapToRewardClaimingType(from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardClaiming) -> RewardClaimingType {
        switch type {
        case .auto: .auto
        case .manual: .manual
        }
    }

    func mapToRewardScheduleType(
        from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardScheduleType,
        item: StakingTokenItem
    ) throws -> RewardScheduleType {
        switch item.network.asStakeKitNetworkType {
        case .solana: .days(min: 2, max: 3)
        case .cosmos: .seconds(min: 5, max: 12)
        case .tron: .daily
        case .binance: .daily
        case .ethereum where item.contractAddress == StakingConstants.polygonContractAddress: .daily
        case .ton: .days(min: 1, max: 2)
        default: .generic(type.rawValue)
        }
    }
}

public enum StakeKitMapperError: Error, LocalizedError {
    case notImplement
    case noData(String)
    case tronTransactionMappingFailed

    public var errorDescription: String? {
        switch self {
        case .notImplement: "Not implemented"
        case .noData(let string): string
        case .tronTransactionMappingFailed: "TronTransactionMappingFailed"
        }
    }
}

private extension StakingTokenItem {
    var rewardsIncludedInBalance: Bool {
        switch network {
        case .cardano: true
        default: false
        }
    }
}
