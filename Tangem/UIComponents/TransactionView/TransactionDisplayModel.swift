//
//  TransactionDisplayModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

/// View-decision payload for a redesigned transaction row/chip.
///
/// Single switch over `transactionType × status × isOutgoing × isFromYieldContract` produces
/// title + subtitle + style. Baked once at `TransactionViewModel` construction so SwiftUI body
/// re-evaluations don't re-run the matrix.
struct TransactionDisplayModel: Hashable {
    let title: String
    let subtitle: Subtitle?
    let style: Style

    enum Style: Hashable {
        case row
        case chip
    }

    enum Subtitle: Hashable {
        /// Plain string subtitle (yield enter/topup/exit copy or address fallback).
        case text(String)
        /// Direction prefix + structured owner — view picks punctuation and avatar layout.
        case owner(direction: Direction, owner: TransactionViewModel.SubtitleOwner)
    }

    enum Direction: Hashable {
        case incoming
        case outgoing
    }
}

extension TransactionDisplayModel {
    static func make(
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status,
        isOutgoing: Bool,
        isFromYieldContract: Bool,
        legacyName: String,
        amount: String,
        addressDestination: String?,
        subtitleOwner: TransactionViewModel.SubtitleOwner?
    ) -> TransactionDisplayModel {
        TransactionDisplayModel(
            title: title(
                transactionType: transactionType,
                status: status,
                isOutgoing: isOutgoing,
                isFromYieldContract: isFromYieldContract,
                legacyName: legacyName
            ),
            subtitle: subtitle(
                transactionType: transactionType,
                isOutgoing: isOutgoing,
                isFromYieldContract: isFromYieldContract,
                amount: amount,
                addressDestination: addressDestination,
                subtitleOwner: subtitleOwner
            ),
            style: isChipStyle(transactionType: transactionType) ? .chip : .row
        )
    }

    private static func isChipStyle(transactionType: TransactionViewModel.TransactionType) -> Bool {
        switch transactionType {
        case .stake, .unstake, .vote, .restake, .withdraw,
             .approve,
             .yieldEnter, .yieldEnterCoin,
             .yieldWithdraw, .yieldWithdrawCoin,
             .yieldInit, .yieldDeploy, .yieldReactivate,
             .yieldTopup, .yieldSend:
            return true
        case .transfer, .swap, .claimRewards, .operation, .unknownOperation,
             .gaslessTransactionFee, .gaslessTransfer, .tangemPay:
            return false
        }
    }

    private static func title(
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status,
        isOutgoing: Bool,
        isFromYieldContract: Bool,
        legacyName: String
    ) -> String {
        switch transactionType {
        case .transfer,
             .yieldSend where isOutgoing,
             .yieldSend where !isFromYieldContract:
            return directionalTitle(isOutgoing: isOutgoing, status: status)
        case .swap:
            return statusTitle(status: status, progress: Localization.commonSwapping, done: Localization.commonSwapped)
        case .approve:
            return statusTitle(status: status, progress: Localization.commonApproving, done: Localization.commonApproved)
        case .stake:
            return statusTitle(status: status, progress: Localization.commonStaking, done: Localization.commonStaked)
        default:
            return legacyName
        }
    }

    private static func subtitle(
        transactionType: TransactionViewModel.TransactionType,
        isOutgoing: Bool,
        isFromYieldContract: Bool,
        amount: String,
        addressDestination: String?,
        subtitleOwner: TransactionViewModel.SubtitleOwner?
    ) -> Subtitle? {
        if let yieldText = yieldModeSubtitleText(
            transactionType: transactionType,
            isFromYieldContract: isFromYieldContract,
            amount: amount
        ) {
            return .text(yieldText)
        }

        if let owner = subtitleOwner {
            return .owner(direction: isOutgoing ? .outgoing : .incoming, owner: owner)
        }

        return addressDestination.map(Subtitle.text)
    }

    private static func yieldModeSubtitleText(
        transactionType: TransactionViewModel.TransactionType,
        isFromYieldContract: Bool,
        amount: String
    ) -> String? {
        switch transactionType {
        case .yieldEnter:
            return Localization.yieldModuleTransactionEnterSubtitle(amount)
        case .yieldTopup:
            return Localization.yieldModuleTransactionTopupSubtitle(amount)
        case .yieldWithdraw,
             .yieldSend where isFromYieldContract:
            return Localization.yieldModuleTransactionExitSubtitle(amount)
        default:
            return nil
        }
    }

    private static func directionalTitle(isOutgoing: Bool, status: TransactionViewModel.Status) -> String {
        switch (isOutgoing, status) {
        case (true, .failed):
            return Localization.commonActionFailed(Localization.commonSending)
        case (false, .failed):
            return Localization.commonActionFailed(Localization.commonReceiving)
        case (true, .inProgress):
            return Localization.commonSending
        case (false, .inProgress):
            return Localization.commonReceiving
        case (true, _):
            return Localization.commonSent
        case (false, _):
            return Localization.commonReceived
        }
    }

    private static func statusTitle(status: TransactionViewModel.Status, progress: String, done: String) -> String {
        switch status {
        case .failed: Localization.commonActionFailed(progress)
        case .inProgress: progress
        case .confirmed, .undefined: done
        }
    }
}
