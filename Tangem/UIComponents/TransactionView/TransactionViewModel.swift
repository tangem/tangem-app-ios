//
//  PendingTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemLocalization
import TangemAssets
import TangemFoundation
import TangemMacro

struct TransactionViewModel: Hashable, Identifiable {
    let id: ViewModelId
    let hash: String
    let icon: TransactionViewIconViewData
    let amount: TransactionViewAmountViewData

    /// Resolved at construction time by the `SubtitleOwnerResolver` for records that have a
    /// single resolvable counterparty. `nil` for legacy callers that don't run resolution.
    let subtitleOwner: SubtitleOwner?

    /// Pre-computed title/subtitle/style for the redesigned row/chip. Baked once so SwiftUI body
    /// re-evaluations don't re-run the matrix.
    let display: TransactionDisplayModel

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
        let base = baseTransactionDescription()
        guard let cardName else { return base }
        guard let base else { return cardName }
        return "\(base) \(AppConstants.dotSign) \(cardName)"
    }

    private func baseTransactionDescription() -> String? {
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

        return addressDestination
    }

    var addressDestination: String? {
        Self.computeAddressDestination(
            interactionAddress: interactionAddress,
            transactionType: transactionType,
            isOutgoing: isOutgoing
        )
    }

    var name: String {
        Self.legacyName(
            transactionType: transactionType,
            isOutgoing: isOutgoing,
            isFromYieldContract: isFromYieldContract
        )
    }

    let interactionAddress: InteractionAddressType
    let transactionType: TransactionType
    let status: Status
    let isOutgoing: Bool
    let isFromYieldContract: Bool
    private let timeFormatted: String?
    private let cardName: String?

    init(
        hash: String,
        // Index of an individual transaction within the parent transaction (if applicable).
        // For example, a single EVM transaction may consist of multiple token transactions (with indices 0, 1, 2 and so on)
        index: Int,
        interactionAddress: InteractionAddressType,
        timeFormatted: String?,
        amount: String,
        value: String,
        currencyCode: String,
        isOutgoing: Bool,
        transactionType: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status,
        isFromYieldContract: Bool,
        subtitleOwner: SubtitleOwner? = nil,
        cardName: String? = nil
    ) {
        id = ViewModelId(hash: hash, index: index, statusRawValue: status.rawValue)
        self.hash = hash
        icon = TransactionViewIconViewData(type: transactionType, status: status, isOutgoing: isOutgoing)
        self.amount = TransactionViewAmountViewData(
            amount: amount,
            value: value,
            currencyCode: currencyCode,
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
        self.subtitleOwner = subtitleOwner
        self.cardName = cardName

        display = TransactionDisplayModel.make(
            transactionType: transactionType,
            status: status,
            isOutgoing: isOutgoing,
            isFromYieldContract: isFromYieldContract,
            legacyName: Self.legacyName(transactionType: transactionType, isOutgoing: isOutgoing, isFromYieldContract: isFromYieldContract),
            amount: amount,
            addressDestination: Self.computeAddressDestination(
                interactionAddress: interactionAddress,
                transactionType: transactionType,
                isOutgoing: isOutgoing
            ),
            subtitleOwner: subtitleOwner
        )
    }

    /// Mirrors `name` but as a static so it can be called during `init` before stored properties
    /// are fully assigned. Kept private to the type.
    private static func legacyName(
        transactionType: TransactionType,
        isOutgoing: Bool,
        isFromYieldContract: Bool
    ) -> String {
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
        }
    }

    /// Mirrors the `addressDestination` getter as a static so the display model can be built
    /// during `init` (before all stored properties are assigned).
    private static func computeAddressDestination(
        interactionAddress: InteractionAddressType,
        transactionType: TransactionType,
        isOutgoing: Bool
    ) -> String? {
        switch interactionAddress {
        case .user(let address):
            return isOutgoing
                ? Localization.transactionHistoryTransactionToAddress(address)
                : Localization.transactionHistoryTransactionFromAddress(address)
        case .contract(let address) where transactionType.isYieldWithdrawCoin,
             .contract(let address) where transactionType.isYieldEnterCoin,
             .contract(let address) where transactionType.isYieldInit,
             .contract(let address) where transactionType.isYieldDeploy:
            return Localization.transactionHistoryTransactionForAddress(address)
        case .contract(let address):
            return Localization.transactionHistoryContractAddress(address)
        case .multiple:
            return isOutgoing
                ? Localization.transactionHistoryTransactionToAddress(Localization.transactionHistoryMultipleAddresses)
                : Localization.transactionHistoryTransactionFromAddress(Localization.transactionHistoryMultipleAddresses)
        case .custom(let message):
            return message
        case .staking(let validator):
            return validator.flatMap { Localization.stakingValidator + ": " + $0 }
        }
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

        case tangemPay(TangemPayTransactionType)
    }

    enum TangemPayTransactionType: Hashable {
        /// Spend fiat value
        case spend(name: String, icon: URL?, isDeclined: Bool, isNegativeAmount: Bool)

        /// Crypto transfers
        case transfer(name: String)

        /// Service fee
        case fee(name: String)

        var name: String {
            switch self {
            case .spend(let name, _, _, _): name
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

    /// Counterparty rendered alongside the direction prefix in the redesigned subtitle.
    /// One of: a named account inside the current wallet, a named wallet (single-account mode),
    /// an account + wallet pair (cross-wallet transfer in accounts-mode), or an unresolved
    /// external address that falls back to blockies + truncated hex.
    enum SubtitleOwner: Hashable {
        case account(name: String, icon: AccountIconView.ViewData)
        case wallet(name: String)
        case accountInWallet(accountName: String, accountIcon: AccountIconView.ViewData, walletName: String)
        /// Pre-rendered blockies are carried alongside the address so the SwiftUI body doesn't
        /// rebuild `AddressIconViewModel` on every recomputation (long lists scroll-allocate).
        case unresolved(short: String, fullAddress: String, blockiesImage: UIImage?)

        static func == (lhs: SubtitleOwner, rhs: SubtitleOwner) -> Bool {
            switch (lhs, rhs) {
            case (.account(let lName, let lIcon), .account(let rName, let rIcon)):
                return lName == rName && lIcon == rIcon
            case (.wallet(let lName), .wallet(let rName)):
                return lName == rName
            case (.accountInWallet(let lAcc, let lIcon, let lWallet), .accountInWallet(let rAcc, let rIcon, let rWallet)):
                return lAcc == rAcc && lIcon == rIcon && lWallet == rWallet
            case (.unresolved(let lShort, let lAddress, _), .unresolved(let rShort, let rAddress, _)):
                return lShort == rShort && lAddress == rAddress
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .account(let name, let icon):
                hasher.combine(0)
                hasher.combine(name)
                hasher.combine(icon)
            case .wallet(let name):
                hasher.combine(1)
                hasher.combine(name)
            case .accountInWallet(let accountName, let accountIcon, let walletName):
                hasher.combine(2)
                hasher.combine(accountName)
                hasher.combine(accountIcon)
                hasher.combine(walletName)
            case .unresolved(let short, let fullAddress, _):
                hasher.combine(3)
                hasher.combine(short)
                hasher.combine(fullAddress)
            }
        }
    }
}
