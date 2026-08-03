//
//  StakeFlowState.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// The unified state of the V2 staking flow, produced by a `StakingFlowProvider` and published by `StakeModel`.
///
/// Simple flows (unstake / restake / single action) only ever produce `loading` / `ready` / `failure`;
/// the `prerequisite` case is reached only when a provider runs the corresponding stage, so there is no
/// per-flow branching to express it.
enum StakeFlowState {
    case loading
    case ready(Ready)
    case failure(StakeFlowError)
    /// Staking cannot proceed until a prerequisite (approval, account creation) is satisfied.
    case prerequisite(StakePrerequisite)

    struct Ready {
        let amount: Decimal
        let fee: Decimal
        let isFeeIncluded: Bool
        let stakesCount: Int?
        /// Enter-only extras (stake): how much to free up for "max" when the fee is included, and whether
        /// the position already holds a stake on a different validator. Default-empty for other actions.
        let amountToReduce: Decimal?
        let stakeOnDifferentValidator: Bool

        init(
            amount: Decimal,
            fee: Decimal,
            isFeeIncluded: Bool,
            stakesCount: Int?,
            amountToReduce: Decimal? = nil,
            stakeOnDifferentValidator: Bool = false
        ) {
            self.amount = amount
            self.fee = fee
            self.isFeeIncluded = isFeeIncluded
            self.stakesCount = stakesCount
            self.amountToReduce = amountToReduce
            self.stakeOnDifferentValidator = stakeOnDifferentValidator
        }
    }
}

/// A precondition that must be met before the stake transaction can be sent.
///
/// Every prerequisite shares the same two phases: `required` carries what's needed to satisfy it, and
/// `inProgress` means the satisfying transaction is in flight.
enum StakePrerequisite {
    case approve(Approve)
    case accountInitialization(AccountInitialization)

    enum Approve {
        case required(ApproveTransactionData, stakingFee: Decimal)
        case inProgress(stakingFee: Decimal)
    }

    enum AccountInitialization {
        case required(initializationFee: Fee, transactionFee: Fee)
        case inProgress
    }
}

/// The ways the V2 staking flow can fail.
///
/// The fee rides on `.transaction` alone: it is the only failure surfaced *after* fee estimation
/// (the BlockchainSdk balance / dust / fee-coverage checks). `.staking` carries the yield's min/max
/// amount rule and is evaluated *before* any fee exists; `.network` covers estimate / allowance lookups.
enum StakeFlowError: Error {
    case transaction(ValidationError, fee: Decimal)
    case staking(StakingValidationError)
    case network(Error)
}

// MARK: - Presentation

extension StakeFlowState {
    /// How the fee row should render for the current state.
    enum FeePresentation {
        case loading
        case value(Decimal)
        case failure(Error)
    }

    /// Whether the main action button can fire. Only a fully resolved amount or a pending approval
    /// (whose main button performs the approval) is actionable; account creation is driven from a
    /// notification, not the main button.
    var isReadyToSend: Bool {
        switch self {
        case .ready, .prerequisite(.approve(.required)):
            true
        case .loading, .failure, .prerequisite:
            false
        }
    }

    var feePresentation: FeePresentation {
        switch self {
        case .loading:
            .loading
        case .ready(let ready):
            .value(ready.fee)
        case .prerequisite(.approve(.required(_, let stakingFee))),
             .prerequisite(.approve(.inProgress(let stakingFee))):
            .value(stakingFee)
        case .prerequisite(.accountInitialization(.required(_, let transactionFee))):
            .value(transactionFee.amount.value)
        case .prerequisite(.accountInitialization(.inProgress)):
            .failure(StakeModelError.accountIsNotInitialized)
        case .failure(.transaction(_, let fee)):
            .value(fee)
        case .failure(.staking(let error)):
            .failure(error)
        case .failure(.network(let error)):
            .failure(error)
        }
    }
}
