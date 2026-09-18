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
    let title: TitleContent
    let subtitle: Subtitle?
    let style: Style

    /// Titles glued from two resources keep their halves apart, so the chip can paint the trailing one
    /// with the primary colour without searching for it inside the finished string.
    enum TitleContent: Hashable {
        case plain(String)
        case emphasizedSuffix(prefix: String, emphasized: String)

        var fullText: String {
            switch self {
            case .plain(let text): text
            case .emphasizedSuffix(let prefix, let emphasized): prefix + emphasized
            }
        }
    }

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
        /// Yield provider standing in for a counterparty — `to: ⬤ Aave` on Supply, `from:` on Withdraw.
        case provider(direction: Direction)
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
                addressDestination: addressDestination,
                subtitleOwner: subtitleOwner,
                expressSubtitle: expressSubtitle
            ),
            style: isChipStyle(transactionType: transactionType) ? .chip : .row
        )
    }

    /// Supply, Withdraw and the contract lifecycle calls are full rows; the rest of the taxonomy is
    /// described in the header of `TransactionChipRedesigned`.
    private static func isChipStyle(transactionType: TransactionViewModel.TransactionType) -> Bool {
        switch transactionType {
        case .stake, .unstake, .vote, .restake, .withdraw,
             .approve,
             .yieldEnter, .yieldEnterCoin,
             .yieldWithdraw, .yieldWithdrawCoin:
            return true
        case .yieldSend, .yieldTopup, .yieldInit, .yieldDeploy, .yieldReactivate,
             .transfer, .swap, .onramp, .claimRewards, .operation, .unknownOperation,
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
    ) -> TitleContent {
        switch transactionType {
        case .transfer:
            return transferTitle(isOutgoing: isOutgoing, status: status, subtitleOwner: subtitleOwner)
        case .yieldSend where transactionType.isTransferLikeYieldSend(isOutgoing: isOutgoing, isFromYieldContract: isFromYieldContract):
            return transferTitle(isOutgoing: isOutgoing, status: status, subtitleOwner: subtitleOwner)
        case .yieldSend:
            return statusTitle(
                status: status,
                progress: Localization.commonWithdrawing,
                done: Localization.transactionHistoryWithdrawn,
                failed: Localization.transactionHistoryStatusWithdrawFailed
            )
        case .yieldTopup:
            return statusTitle(
                status: status,
                progress: Localization.commonSupplying,
                done: Localization.transactionHistorySupplied,
                failed: Localization.transactionHistoryStatusSupplyFailed
            )
        case .yieldEnter, .yieldEnterCoin:
            return yieldModeTitle(
                status: status,
                state: .enabled,
                progress: Localization.transactionHistoryEnablingYieldMode,
                failed: Localization.transactionHistoryStatusEnablingYieldModeFailed
            )
        case .yieldWithdraw, .yieldWithdrawCoin:
            return yieldModeTitle(
                status: status,
                state: .disabled,
                progress: Localization.transactionHistoryDisablingYieldMode,
                failed: Localization.transactionHistoryStatusDisablingYieldModeFailed
            )
        case .swap:
            return statusTitle(
                status: status,
                progress: Localization.commonSwapping,
                done: Localization.commonSwapped,
                failed: Localization.transactionHistoryStatusSwapFailed
            )
        case .onramp:
            return statusTitle(
                status: status,
                progress: Localization.transactionHistoryStatusToppingUp,
                done: Localization.txHistoryOnrampToppedUp,
                failed: Localization.transactionHistoryStatusTopUpFailed
            )
        case .approve:
            return statusTitle(
                status: status,
                progress: Localization.commonApproving,
                done: Localization.commonApproved,
                failed: Localization.transactionHistoryStatusApproveFailed
            )
        case .stake:
            return statusTitle(
                status: status,
                progress: Localization.commonStaking,
                done: Localization.commonStaked,
                failed: Localization.transactionHistoryStatusStakeFailed
            )
        case .unstake:
            return statusTitle(
                status: status,
                progress: Localization.stakingUnstaking,
                done: Localization.stakingUnstaked,
                failed: Localization.transactionHistoryStatusUnstakeFailed
            )
        case .restake:
            return statusTitle(
                status: status,
                progress: Localization.transactionHistoryStatusRestakingRewards,
                done: Localization.transactionHistoryRewardsRestaked,
                failed: Localization.transactionHistoryStatusRewardsRestakeFailed
            )
        case .claimRewards:
            return statusTitle(
                status: status,
                progress: Localization.transactionHistoryStatusClaimingRewards,
                done: Localization.transactionHistoryStatusRewardsClaimed,
                failed: Localization.transactionHistoryStatusRewardsClaimFailed
            )
        default:
            return .plain(legacyName)
        }
    }

    private static func subtitle(
        transactionType: TransactionViewModel.TransactionType,
        isOutgoing: Bool,
        isFromYieldContract: Bool,
        addressDestination: String?,
        subtitleOwner: TransactionViewModel.SubtitleOwner?,
        expressSubtitle: ExpressSubtitle?
    ) -> Subtitle? {
        if isSubtitleSuppressed(transactionType: transactionType) {
            return nil
        }

        if let expressSubtitle {
            return .express(expressSubtitle)
        }

        if let direction = yieldProviderDirection(
            transactionType: transactionType,
            isFromYieldContract: isFromYieldContract
        ) {
            return .provider(direction: direction)
        }

        if case .claimRewards = transactionType {
            return .text(Localization.transactionHistoryEarnedFromStake)
        }

        if let owner = subtitleOwner {
            return .owner(direction: isOutgoing ? .outgoing : .incoming, owner: owner)
        }

        return addressDestination.map(Subtitle.text)
    }

    /// The Yield Mode enable/disable chips are label-only, so they take neither the yield copy nor the
    /// counterparty every other type falls back to.
    private static func isSubtitleSuppressed(transactionType: TransactionViewModel.TransactionType) -> Bool {
        switch transactionType {
        case .yieldEnter, .yieldEnterCoin, .yieldWithdraw, .yieldWithdrawCoin:
            return true
        case .yieldSend, .yieldTopup, .yieldInit, .yieldDeploy, .yieldReactivate,
             .transfer, .swap, .onramp, .stake, .unstake, .vote, .restake, .withdraw,
             .claimRewards, .approve, .operation, .unknownOperation,
             .gaslessTransactionFee, .gaslessTransfer, .tangemPay:
            return false
        }
    }

    /// Supply and Withdraw name the yield provider instead of an address — the funds go to Aave and come back from it.
    private static func yieldProviderDirection(
        transactionType: TransactionViewModel.TransactionType,
        isFromYieldContract: Bool
    ) -> Direction? {
        switch transactionType {
        case .yieldTopup:
            return .outgoing
        case .yieldSend where isFromYieldContract:
            return .incoming
        case .yieldSend, .yieldEnter, .yieldEnterCoin, .yieldWithdraw, .yieldWithdrawCoin,
             .yieldInit, .yieldDeploy, .yieldReactivate,
             .transfer, .swap, .onramp, .stake, .unstake, .vote, .restake, .withdraw,
             .claimRewards, .approve, .operation, .unknownOperation,
             .gaslessTransactionFee, .gaslessTransfer, .tangemPay:
            return nil
        }
    }

    private static func transferTitle(
        isOutgoing: Bool,
        status: TransactionViewModel.Status,
        subtitleOwner: TransactionViewModel.SubtitleOwner?
    ) -> TitleContent {
        if subtitleOwner?.isOwnWallet == true {
            return statusTitle(
                status: status,
                progress: Localization.transactionHistoryStatusTransferring,
                done: Localization.commonTransferred,
                failed: Localization.transactionHistoryStatusTransferFailed
            )
        }

        return directionalTitle(isOutgoing: isOutgoing, status: status)
    }

    private static func directionalTitle(isOutgoing: Bool, status: TransactionViewModel.Status) -> TitleContent {
        switch (isOutgoing, status) {
        case (true, .failed):
            return .plain(Localization.transactionHistoryStatusSendFailed)
        case (false, .failed):
            return .plain(Localization.transactionHistoryStatusReceiveFailed)
        case (true, .inProgress):
            return .plain(Localization.commonSending)
        case (false, .inProgress):
            return .plain(Localization.commonReceiving)
        case (true, _):
            return .plain(Localization.commonSent)
        case (false, _):
            return .plain(Localization.commonReceived)
        }
    }

    private enum YieldModeState {
        case enabled
        case disabled

        var word: String {
            switch self {
            case .enabled: Localization.commonEnabled
            case .disabled: Localization.commonDisabled
            }
        }
    }

    /// The settled title is glued from two resources so the state word keeps its own capitalization while
    /// the mode name stays the one shared with the rest of the app.
    private static func yieldModeTitle(
        status: TransactionViewModel.Status,
        state: YieldModeState,
        progress: String,
        failed: String
    ) -> TitleContent {
        switch status {
        case .failed: .plain(failed)
        case .inProgress: .plain(progress)
        case .confirmed, .undefined: .emphasizedSuffix(prefix: Localization.commonYieldModeInline + " ", emphasized: state.word)
        }
    }

    private static func statusTitle(status: TransactionViewModel.Status, progress: String, done: String, failed: String) -> TitleContent {
        switch status {
        case .failed: .plain(failed)
        case .inProgress: .plain(progress)
        case .confirmed, .undefined: .plain(done)
        }
    }
}
