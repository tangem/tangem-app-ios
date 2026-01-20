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
import TangemMacro

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

    var transactionDescriptionTruncationMode: Text.TruncationMode {
        switch transactionType {
        case .yieldEnter, .yieldTopup, .yieldWithdraw:
            .tail
        case .yieldSend where isFromYieldContract:
            .tail
        default:
            .middle
        }
    }

    func getTransactionDescription() -> String? {
        switch transactionType {
        case .yieldEnter:
            return Localization.yieldModuleTransactionEnterSubtitle(amount.amount)

        case .yieldTopup:
            return Localization.yieldModuleTransactionTopupSubtitle(amount.amount)

        case .yieldSend where isOutgoing:
            return localizeDestination

        case .yieldWithdraw,
             .yieldSend where isFromYieldContract:
            return Localization.yieldModuleTransactionExitSubtitle(amount.amount)

        default:
            return localizeDestination
        }
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
        case .contract(let address) where transactionType.isYieldWithdrawCoin:
            return Localization.transactionHistoryTransactionForAddress(address)
        case .contract(let address) where transactionType.isYieldEnterCoin:
            return Localization.transactionHistoryTransactionForAddress(address)
        case .contract(let address) where transactionType.isYieldInit:
            return Localization.transactionHistoryTransactionForAddress(address)
        case .contract(let address) where transactionType.isYieldDeploy:
            return Localization.transactionHistoryTransactionForAddress(address)
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
        case .yieldSend where isOutgoing,
             .yieldSend where !isFromYieldContract: Localization.commonTransfer
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
        case .tangemPay(let type): type.name
        case .yieldDeploy: Localization.yieldModuleTransactionDeployContract
        case .yieldEnter, .yieldEnterCoin: Localization.yieldModuleTransactionEnter
        case .yieldInit: Localization.yieldModuleTransactionInitialize
        case .yieldReactivate: Localization.yieldModuleTransactionReactivate
        case .yieldSend: Localization.yieldModuleTransactionWithdraw
        case .yieldTopup: Localization.yieldModuleTransactionTopup
        case .yieldWithdraw, .yieldWithdrawCoin: Localization.yieldModuleTransactionExit
        case .gaslessTransactionFee: Localization.gaslessTransactionFee
        case .gaslessTransfer: Localization.transactionHistoryOperation
        }
    }

    private let interactionAddress: InteractionAddressType
    private let timeFormatted: String?
    private let isOutgoing: Bool
    private let isFromYieldContract: Bool
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
        status: TransactionViewModel.Status,
        isFromYieldContract: Bool
    ) {
        id = ViewModelId(hash: hash, index: index, statusRawValue: status.rawValue)
        self.hash = hash
        icon = TransactionViewIconViewData(type: transactionType, status: status, isOutgoing: isOutgoing)
        self.amount = TransactionViewAmountViewData(
            amount: amount,
            type: transactionType,
            status: status,
            isOutgoing: isOutgoing,
            isFromYieldContract: isFromYieldContract
        )

        self.interactionAddress = interactionAddress
        self.timeFormatted = timeFormatted
        self.isOutgoing = isOutgoing
        self.isFromYieldContract = isFromYieldContract
        self.transactionType = transactionType
        self.status = status
    }
}

extension TransactionViewModel {
    /// An opaque unique identity for use with the `Identifiable` protocol.
    struct ViewModelId: Hashable {
        fileprivate let hash: String
        fileprivate let index: Int
        fileprivate let statusRawValue: String
    }

    enum InteractionAddressType: Hashable {
        case user(_ address: String)
        case contract(_ address: String)
        case multiple(_ addresses: [String])
        // Temp solution for Visa
        case custom(message: String)
        case staking(validator: String?)
    }

    @CaseFlagable
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
        case unknownOperation
        case operation(name: String)

        case yieldDeploy
        case yieldEnter
        case yieldEnterCoin
        case yieldInit
        case yieldReactivate
        case yieldSend
        case yieldTopup
        case yieldWithdraw
        case yieldWithdrawCoin
        case gaslessTransactionFee
        case gaslessTransfer

        case tangemPay(TangemPayTransactionType)
    }

    enum TangemPayTransactionType: Hashable {
        /// Spend fiat value
        case spend(name: String, icon: URL?, isDeclined: Bool)

        /// Crypto transfers
        case transfer(name: String)

        /// Service fee
        case fee(name: String)

        var name: String {
            switch self {
            case .spend(let name, _, _): name
            case .transfer(let name): name
            case .fee(let name): name
            }
        }
    }

    enum Status: String {
        case inProgress
        case failed
        case confirmed
        case undefined
    }
}
