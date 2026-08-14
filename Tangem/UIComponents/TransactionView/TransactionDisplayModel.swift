//
//  TransactionDisplayModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

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
        /// Express (swap / onramp) counterparty: direction prefix + counterparty currency icon/symbol,
        /// and an optional "in [account/wallet]" segment when the counterparty leg lives elsewhere.
        case express(ExpressSubtitle)
    }

    /// Counterparty descriptor for an Express row subtitle (e.g. `to: POL in Family`).
    struct ExpressSubtitle: Hashable {
        enum Leading: Hashable {
            /// Crypto counterparty (swap) — the other token's icon.
            case token(TokenIconInfo)
            /// Fiat counterparty (onramp) — the paid currency's flag.
            case fiat(url: URL?)
        }

        let direction: Direction
        let leading: Leading
        let symbol: String
        let owner: TransactionViewModel.SubtitleOwner?
    }

    enum Direction: Hashable {
        case incoming
        case outgoing

        /// Localised `from:` / `to:` prefix, recovered from the address templates by formatting them with an
        /// empty value and stripping trailing whitespace — keeps the punctuation locale-correct without new keys.
        var localizedPrefix: String {
            let template = switch self {
            case .incoming: Localization.transactionHistoryTransactionFromAddress("")
            case .outgoing: Localization.transactionHistoryTransactionToAddress("")
            }
            return template.trimmingCharacters(in: .whitespacesAndNewlines)
        }
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
        subtitleOwner: TransactionViewModel.SubtitleOwner?,
        expressSubtitle: ExpressSubtitle?
    ) -> TransactionDisplayModel {
        TransactionDisplayModel(
            title: title(
                transactionType: transactionType,
                status: status,
                isOutgoing: isOutgoing,
                isFromYieldContract: isFromYieldContract,
                legacyName: legacyName,
                subtitleOwner: subtitleOwner
            ),
            subtitle: subtitle(
                transactionType: transactionType,
                isOutgoing: isOutgoing,
                isFromYieldContract: isFromYieldContract,
                amount: amount,
                addressDestination: addressDestination,
                subtitleOwner: subtitleOwner,
                expressSubtitle: expressSubtitle
            ),
            style: isChipStyle(
                transactionType: transactionType,
                isOutgoing: isOutgoing,
                isFromYieldContract: isFromYieldContract
            ) ? .chip : .row
        )
    }

    private static func isChipStyle(
        transactionType: TransactionViewModel.TransactionType,
        isOutgoing: Bool,
        isFromYieldContract: Bool
    ) -> Bool {
        switch transactionType {
        case .stake, .unstake, .vote, .restake, .withdraw,
             .approve,
             .yieldEnter, .yieldEnterCoin,
             .yieldWithdraw, .yieldWithdrawCoin,
             .yieldInit, .yieldDeploy, .yieldReactivate,
             .yieldTopup:
            return true
        case .yieldSend:
            return !transactionType.isTransferLikeYieldSend(isOutgoing: isOutgoing, isFromYieldContract: isFromYieldContract)
        case .transfer, .swap, .onramp, .claimRewards, .operation, .unknownOperation,
             .gaslessTransactionFee, .gaslessTransfer, .tangemPay:
            return false
        }
    }

    static func title(
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status,
        isOutgoing: Bool,
        isFromYieldContract: Bool,
        legacyName: String,
        subtitleOwner: TransactionViewModel.SubtitleOwner?
    ) -> String {
        switch transactionType {
        case .transfer:
            return transferTitle(isOutgoing: isOutgoing, status: status, subtitleOwner: subtitleOwner)
        case .yieldSend where transactionType.isTransferLikeYieldSend(isOutgoing: isOutgoing, isFromYieldContract: isFromYieldContract):
            return transferTitle(isOutgoing: isOutgoing, status: status, subtitleOwner: subtitleOwner)
        case .swap:
            return statusTitle(status: status, progress: Localization.commonSwapping, done: Localization.commonSwapped)
        case .onramp:
            return statusTitle(status: status, progress: Localization.txHistoryOnrampTopUp, done: Localization.txHistoryOnrampToppedUp)
        case .approve:
            return statusTitle(status: status, progress: Localization.commonApproving, done: Localization.commonApproved)
        case .stake:
            return statusTitle(status: status, progress: Localization.commonStaking, done: Localization.commonStaked)
        case .unstake:
            return statusTitle(status: status, progress: Localization.stakingUnstaking, done: Localization.stakingUnstaked)
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
        subtitleOwner: TransactionViewModel.SubtitleOwner?,
        expressSubtitle: ExpressSubtitle?
    ) -> Subtitle? {
        if let expressSubtitle {
            return .express(expressSubtitle)
        }

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

    private static func transferTitle(
        isOutgoing: Bool,
        status: TransactionViewModel.Status,
        subtitleOwner: TransactionViewModel.SubtitleOwner?
    ) -> String {
        if subtitleOwner?.isOwnWallet == true {
            return statusTitle(status: status, progress: Localization.commonTransfer, done: Localization.commonTransferred)
        }

        return directionalTitle(isOutgoing: isOutgoing, status: status)
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
