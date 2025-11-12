//
//  PendingTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct TransactionViewModel: Hashable, Identifiable {
    let id: ViewModelId
    let hash: String
    let icon: TransactionViewIconViewData
    let amount: TransactionViewAmountViewData

    var inProgress: Bool {
        status == .inProgress
    }

    var subtitleText: String {
        return timeFormatted ?? "-"
    }

    var localizeDestination: String? {
        if status == .failed {
            return Localization.commonTransactionFailed
        }

        switch interactionAddress {
        case .user(let address):
            if isOutgoing {
                return Localization.transactionHistoryTransactionToAddress(address)
            } else {
                return Localization.transactionHistoryTransactionFromAddress(address)
            }
        case .contract(let address):
            return Localization.transactionHistoryContractAddress(address)
        case .multiple:
            if isOutgoing {
                return Localization.transactionHistoryTransactionToAddress(
                    Localization.transactionHistoryMultipleAddresses
                )
            } else {
                return Localization.transactionHistoryTransactionFromAddress(
                    Localization.transactionHistoryMultipleAddresses
                )
            }
        // Temp solution for Visa
        case .custom(let message):
            return message
        case .staking(let validator):
            return validator.flatMap { Localization.stakingValidator + ": " + $0 }
        }
    }

    var name: String {
        switch transactionType {
        case .transfer: Localization.commonTransfer
        case .swap: Localization.commonSwap
        case .approve: Localization.commonApproval
        case .unknownOperation: Localization.transactionHistoryOperation
        case .operation(name: let name): name
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .vote: Localization.stakingVote
        case .withdraw: Localization.stakingWithdraw
        case .claimRewards: Localization.commonClaimRewards
        case .restake: Localization.stakingRestake
        case .yieldSupply: Localization.yieldModuleSupply
        case .tangemPay(name: let name, _, _): name
        case .tangemPayTransfer(name: let name): name
        }
    }

    private let interactionAddress: InteractionAddressType
    private let timeFormatted: String?
    private let isOutgoing: Bool
    private let transactionType: TransactionType
    private let status: Status

    init(
        hash: String,
        // Index of an individual transaction within the parent transaction (if applicable).
        // For example, a single EVM transaction may consist of multiple token transactions (with indices 0, 1, 2 and so on)
        index: Int,
        interactionAddress: InteractionAddressType,
        timeFormatted: String?,
        amount: String,
        isOutgoing: Bool,
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status
    ) {
        id = ViewModelId(hash: hash, index: index)
        self.hash = hash
        icon = TransactionViewIconViewData(type: transactionType, status: status, isOutgoing: isOutgoing)
        self.amount = TransactionViewAmountViewData(amount: amount, type: transactionType, status: status, isOutgoing: isOutgoing)

        self.interactionAddress = interactionAddress
        self.timeFormatted = timeFormatted
        self.isOutgoing = isOutgoing
        self.transactionType = transactionType
        self.status = status
    }
}

extension TransactionViewModel {
    /// An opaque unique identity for use with the `Identifiable` protocol.
    struct ViewModelId: Hashable {
        fileprivate let hash: String
        fileprivate let index: Int
    }

    enum InteractionAddressType: Hashable {
        case user(_ address: String)
        case contract(_ address: String)
        case multiple(_ addresses: [String])
        // Temp solution for Visa
        case custom(message: String)
        case staking(validator: String?)
    }

    enum TransactionType: Hashable {
        case transfer
        case swap
        case stake
        case approve
        case unstake
        case vote
        case withdraw
        case claimRewards
        case restake
        case yieldSupply
        case unknownOperation
        case operation(name: String)

        case tangemPay(name: String, icon: URL?, isDeclined: Bool)
        case tangemPayTransfer(name: String)
    }

    enum Status {
        case inProgress
        case failed
        case confirmed
        case undefined
    }
}
