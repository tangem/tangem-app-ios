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
    var id: ViewModelId { ViewModelId(hash: hash, index: index) }

    let hash: String

    var inProgress: Bool {
        status == .inProgress
    }

    var subtitleText: String {
        return timeFormatted ?? "-"
    }

    var formattedAmount: String? {
        switch transactionType {
        case .approve, .vote, .withdraw, .yieldEnter, .yieldWithdraw, .yieldTopup:
            return nil
        case .transfer, .swap, .operation, .unknownOperation, .stake, .unstake, .claimRewards, .restake, .tangemPay, .tangemPayTransfer, .yieldSupply:
            return amount
        }
    }

    var transactionDescriptionLayoutPriority: Double {
        switch transactionType {
        case .yieldEnter, .yieldTopup, .yieldWithdraw:
            0
        default:
            1
        }
    }

    var transactionDescriptionTruncationMode: Text.TruncationMode {
        switch transactionType {
        case .yieldEnter, .yieldTopup, .yieldWithdraw:
            .tail
        default:
            .middle
        }
    }

    func getTransactionDescription() -> String? {
        switch transactionType {
        case .yieldEnter:
            return Localization.yieldModuleTransactionEnterSubtitle(amount)

        case .yieldTopup:
            return Localization.yieldModuleTransactionTopupSubtitle(amount)

        case .yieldWithdraw:
            return Localization.yieldModuleTransactionExitSubtitle(amount)

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
        case .yieldEnter: Localization.yieldModuleTransactionEnter
        case .yieldWithdraw: Localization.yieldModuleTransactionExit
        case .yieldTopup: Localization.yieldModuleTransactionTopup
        case .tangemPay(name: let name, _, _): name
        case .tangemPayTransfer(name: let name): name
        }
    }

    var icon: Image {
        if status == .failed {
            return Assets.crossBig.image
        }

        switch transactionType {
        case .approve:
            return Assets.approve.image
        case .transfer, .swap, .operation, .unknownOperation, .tangemPayTransfer, .yieldSupply, .yieldEnter, .yieldWithdraw, .yieldTopup:
            return isOutgoing ? Assets.arrowUpMini.image : Assets.arrowDownMini.image
        case .stake, .vote, .restake:
            return Assets.TokenItemContextMenu.menuStaking.image
        case .unstake, .withdraw:
            return Assets.unstakedIcon.image
        case .claimRewards:
            return Assets.dollarMini.image
        case .tangemPay:
            return Assets.Visa.otherTransaction.image
        }
    }

    var iconURL: URL? {
        if case .tangemPay(_, icon: let url, _) = transactionType {
            return url
        }
        return nil
    }

    var iconColor: Color {
        switch status {
        case .inProgress:
            return Colors.Icon.accent
        case .confirmed:
            return Colors.Icon.informative
        case .failed, .undefined:
            return Colors.Icon.warning
        }
    }

    var iconBackgroundColor: Color {
        switch status {
        case .inProgress: return Colors.Icon.accent.opacity(0.1)
        case .confirmed: return Colors.Background.secondary
        case .failed, .undefined: return Colors.Icon.warning.opacity(0.1)
        }
    }

    var amountColor: Color {
        switch status {
        case .failed: return Colors.Text.warning
        default:
            switch transactionType {
            case .tangemPay(_, _, let isDeclined) where isDeclined:
                return Colors.Text.warning

            case .tangemPayTransfer where !isOutgoing:
                return Colors.Text.accent

            default:
                return Colors.Text.primary1
            }
        }
    }

    /// Index of an individual transaction within the parent transaction (if applicable).
    /// For example, a single EVM transaction may consist of multiple token transactions (with indices 0, 1, 2 and so on)
    private let index: Int
    private let interactionAddress: InteractionAddressType
    private let timeFormatted: String?
    private let amount: String
    private let isOutgoing: Bool
    private let transactionType: TransactionType
    private let status: Status

    init(
        hash: String,
        index: Int,
        interactionAddress: InteractionAddressType,
        timeFormatted: String?,
        amount: String,
        isOutgoing: Bool,
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status
    ) {
        self.hash = hash
        self.index = index
        self.interactionAddress = interactionAddress
        self.timeFormatted = timeFormatted
        self.amount = amount
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
        case yieldEnter
        case yieldSupply
        case yieldTopup
        case yieldWithdraw
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
