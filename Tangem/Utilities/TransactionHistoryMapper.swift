//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct TransactionHistoryMapper {
    @Injected(\.smartContractMethodMapper) private var smartContractMethodMapper: SmartContractMethodMapper
    // Temporary: injected to obtain the gasless fee recipient address until it’s provided via app config.
    // Used to detect and classify gasless transaction fee transfers.
    @Injected(\.gaslessTransactionsNetworkManager) private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    private let currencySymbol: String
    private let walletAddresses: [String]
    private let showSign: Bool
    private let isToken: Bool

    private let balanceFormatter = BalanceFormatter()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMMdy")
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMMM, y")
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    init(currencySymbol: String, walletAddresses: [String], showSign: Bool, isToken: Bool) {
        self.currencySymbol = currencySymbol
        self.walletAddresses = walletAddresses
        self.showSign = showSign
        self.isToken = isToken
    }

    // [REDACTED_INFO]: when the redesign toggle is removed, drop the `groupingStyle` parameter,
    // delete the `.day` branch, and inline `.dayThenMonth` as the only behaviour.
    func mapTransactionListItem(
        from records: [TransactionRecord],
        groupingStyle: GroupingStyle = .day,
        subtitleOwnerResolver: SubtitleOwnerResolver? = nil
    ) -> [TransactionListItem] {
        let mapRow = { mapTransactionViewModel($0, subtitleOwnerResolver: subtitleOwnerResolver) }

        switch groupingStyle {
        case .day:
            let grouped = Dictionary(grouping: records, by: { Calendar.current.startOfDay(for: $0.date ?? Date()) })

            return grouped.sorted(by: { $0.key > $1.key }).map { key, value in
                TransactionListItem(
                    header: Self.dateFormatter.string(from: key),
                    items: value.map(mapRow)
                )
            }

        case .dayThenMonth:
            let calendar = Calendar.current
            let currentMonthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()

            let grouped = Dictionary(grouping: records) { record -> GroupingKey in
                let date = record.date ?? Date()
                if date >= currentMonthStart {
                    return .day(calendar.startOfDay(for: date))
                } else {
                    return .month(calendar.dateInterval(of: .month, for: date)?.start ?? date)
                }
            }

            return grouped.sorted(by: { $0.key.sortDate > $1.key.sortDate }).map { key, value in
                let header: String = switch key {
                case .day(let date): Self.longDateFormatter.string(from: date)
                case .month(let date): Self.monthFormatter.string(from: date)
                }
                return TransactionListItem(header: header, items: value.map(mapRow))
            }
        }
    }

    enum GroupingStyle {
        /// All records grouped by day. Legacy transaction history behaviour.
        case day
        /// Current-month records grouped by day; older records collapsed into month buckets.
        case dayThenMonth
    }

    private enum GroupingKey: Hashable {
        case day(Date)
        case month(Date)

        var sortDate: Date {
            switch self {
            case .day(let date), .month(let date): date
            }
        }
    }

    func mapTransactionViewModel(
        _ record: TransactionRecord,
        subtitleOwnerResolver: SubtitleOwnerResolver? = nil
    ) -> TransactionViewModel {
        var timeFormatted: String?
        if let date = record.date {
            timeFormatted = Self.timeFormatter.string(from: date)
        }

        let amount = transferAmount(from: record)
        let interaction = interactionAddress(from: record)

        return TransactionViewModel(
            hash: record.hash,
            index: record.index,
            interactionAddress: interaction,
            timeFormatted: timeFormatted,
            amount: amount.formatted,
            value: amount.value,
            currencyCode: currencySymbol,
            isOutgoing: record.isOutgoing,
            transactionType: transactionType(from: record),
            status: status(from: record),
            isFromYieldContract: record.isFromYieldContract,
            subtitleOwner: subtitleOwnerResolver?.resolve(for: interaction)
        )
    }

    func mapSuggestedRecord(_ record: TransactionRecord) -> SendDestinationSuggestedTransactionRecord? {
        // Suggest address which we've already send the transaction
        guard record.isOutgoing else {
            return nil
        }

        // Only simple transfer
        guard transactionType(from: record) == .transfer else {
            return nil
        }

        // Only for user's address
        guard case .user(let address) = interactionAddress(from: record) else {
            return nil
        }

        let amountFormatted = transferAmount(from: record).formatted
        let date = record.date ?? Date()
        let dateFormatted = Self.dateTimeFormatter.string(from: date)

        return SendDestinationSuggestedTransactionRecord(
            id: record.hash,
            address: address,
            additionalField: nil, // [REDACTED_TODO_COMMENT]
            isOutgoing: record.isOutgoing,
            date: date,
            amountFormatted: amountFormatted,
            dateFormatted: dateFormatted
        )
    }
}

// MARK: - TransactionHistoryMapper

private extension TransactionHistoryMapper {
    struct FormattedAmount {
        let formatted: String
        let value: String
    }

    func transferAmount(from record: TransactionRecord) -> FormattedAmount {
        if record.isOutgoing {
            let sent: Decimal = {
                switch record.source {
                case .single(let source):
                    return source.amount
                case .multiple(let sources):
                    return sources.sum(for: walletAddresses)
                }
            }()

            let change: Decimal = {
                switch record.destination {
                case .single(let destination):
                    return walletAddresses.contains(destination.address.string) ? destination.amount : 0
                case .multiple(let destinations):
                    return destinations.sum(for: walletAddresses)
                }
            }()

            let amount = sent - change
            return getFormattedAmount(amount: amount, record: record)

        } else {
            let received: Decimal = {
                switch record.destination {
                case .single(let destination):
                    return destination.amount
                case .multiple(let destinations):
                    return destinations.sum(for: walletAddresses)
                }
            }()

            return getFormattedAmount(amount: received, record: record)
        }
    }

    func interactionAddress(from record: TransactionRecord) -> TransactionViewModel.InteractionAddressType {
        if let gaslessAddress = makeGaslessTransactionInteractionAddress(from: record) {
            return gaslessAddress
        }

        switch record.type {
        case .transfer:
            if record.isOutgoing {
                return mapToInteractionAddressType(destination: record.destination)
            } else {
                return mapToInteractionAddressType(source: record.source)
            }
        case .staking(_, let validator):
            return .staking(validator: validator)
        default:
            return mapToInteractionAddressType(destination: record.destination)
        }
    }

    func mapToInteractionAddressType(source: TransactionRecord.SourceType) -> TransactionViewModel.InteractionAddressType {
        switch source {
        case .single(let source):
            return .user(source.address)
        case .multiple(let sources):
            let addresses = sources.map { $0.address }.unique()
            if let address = addresses.singleElement {
                return .user(address)
            }

            return .multiple(addresses)
        }
    }

    func mapToInteractionAddressType(destination: TransactionRecord.DestinationType) -> TransactionViewModel.InteractionAddressType {
        switch destination {
        case .single(let destination):
            switch destination.address {
            case .user(let address):
                return .user(address)
            case .contract(let address):
                return .contract(address)
            }
        case .multiple(let destinations):
            let addresses = destinations.compactMap { destination -> String? in
                let address = destination.address.string

                // Remove a change output
                if walletAddresses.contains(address) {
                    return nil
                }

                return address
            }

            if let address = addresses.singleElement {
                return .user(address)
            }

            return .multiple(addresses)
        }
    }

    func transactionType(from record: TransactionRecord) -> TransactionViewModel.TransactionType {
        switch record.type {
        case .transfer:
            return .transfer
        case .contractMethodIdentifier(let id):
            let name = smartContractMethodMapper.getName(for: id)
            return transactionType(fromContractMethodName: name, transactionRecord: record)
        case .contractMethodName(let name):
            return transactionType(fromContractMethodName: name, transactionRecord: record)
        case .staking(let type, _):
            switch type {
            case .stake: return .stake
            case .unstake: return .unstake
            case .vote: return .vote
            case .withdraw: return .withdraw
            case .claimRewards: return .claimRewards
            case .restake: return .restake
            }
        }
    }

    func transactionType(
        fromContractMethodName contractMethodName: String?,
        transactionRecord: TransactionRecord,
    ) -> TransactionViewModel.TransactionType {
        switch contractMethodName?.nilIfEmpty {
        case "transfer": return .transfer
        case "approve": return .approve
        case "swap": return .swap
        case "buyVoucher", "buyVoucherPOL", "delegate", "stakeETH": return .stake
        case "sellVoucher_new", "sellVoucher_newPOL", "undelegate", "unstakeETH": return .unstake
        case "unstakeClaimTokens_new", "unstakeClaimTokens_newPOL", "claim": return .withdraw
        case "withdrawRewards", "withdrawRewardsPOL": return .claimRewards
        case "redelegate": return .restake
        case "yieldEnter" where !isToken: return .yieldEnterCoin
        case "yieldEnter": return .yieldEnter
        case "yieldWithdraw" where !isToken: return .yieldWithdrawCoin
        case "yieldWithdraw": return .yieldWithdraw
        case "yieldReactivate": return .yieldReactivate
        case "yieldTopup": return .yieldTopup
        case "yieldSend": return .yieldSend
        case "yieldDeploy": return .yieldDeploy
        case "yieldInit": return .yieldInit
        case "gaslessTransaction": return mapGaslessTransaction(contractMethodName: "gaslessTransaction", transactionRecord: transactionRecord)
        case .none: return .unknownOperation
        case .some(let name): return .operation(name: name.capitalizingFirstLetter())
        }
    }

    func status(from record: TransactionRecord) -> TransactionViewModel.Status {
        switch record.status {
        case .confirmed:
            return .confirmed
        case .failed:
            return .failed
        case .unconfirmed:
            return .inProgress
        case .undefined:
            return .undefined
        }
    }

    func formatted(amount: Decimal, isOutgoing: Bool) -> FormattedAmount {
        let valueOnly = balanceFormatter.formatDecimal(amount)
        let formatted = balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol)
        guard !amount.isZero, showSign else {
            return FormattedAmount(formatted: formatted, value: valueOnly)
        }

        let prefix = isOutgoing ? AppConstants.minusSign : "+"
        return FormattedAmount(formatted: prefix + formatted, value: prefix + valueOnly)
    }
}

extension TransactionHistoryMapper {
    enum Constants {
        static let maximumFractionDigits = 8
        static let roundingMode: NSDecimalNumber.RoundingMode = .down
    }
}

extension TransactionHistoryMapper {
    func mapGaslessTransaction(contractMethodName: String, transactionRecord: TransactionRecord) -> TransactionViewModel.TransactionType {
        guard contractMethodName == "gaslessTransaction" else {
            assertionFailure("mapGaslessTransaction called with non-gasless transaction method")
            return .unknownOperation
        }

        guard let feeRecipient = gaslessTransactionsNetworkManager.cachedFeeRecipientAddress else {
            return .operation(name: contractMethodName)
        }

        if transactionRecord.isOutgoing, transactionRecord.hasDestination(address: feeRecipient) {
            return .gaslessTransactionFee
        }

        return .gaslessTransfer
    }
}

private extension TransactionHistoryMapper {
    func getFormattedAmount(amount: Decimal, record: TransactionRecord) -> FormattedAmount {
        switch transactionType(from: record) {
        case .yieldEnter, .yieldTopup, .yieldWithdraw:
            return FormattedAmount(
                formatted: balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol),
                value: balanceFormatter.formatDecimal(amount)
            )
        // Kept as a separate case so the `where` guard clearly applies only to `.yieldSend`.
        case .yieldSend where record.isFromYieldContract:
            return FormattedAmount(
                formatted: balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol),
                value: balanceFormatter.formatDecimal(amount)
            )
        default:
            return formatted(amount: amount, isOutgoing: record.isOutgoing)
        }
    }

    func makeGaslessTransactionInteractionAddress(from record: TransactionRecord) -> TransactionViewModel.InteractionAddressType? {
        guard case .contractMethodIdentifier(let id) = record.type,
              let name = smartContractMethodMapper.getName(for: id),
              name == "gaslessTransaction"
        else {
            return nil
        }

        switch (record.isOutgoing, record.destination, record.source) {
        case (true, .single(let destination), _):
            return mapToInteractionAddressType(destination: .single(destination))

        case (false, _, .single(let source)):
            return .user(source.address)

        default:
            return nil
        }
    }
}

private extension Array where Element == TransactionRecord.Destination {
    func sum(for addresses: [String]) -> Decimal {
        filter { destination in
            addresses.contains(destination.address.string)
        }
        .reduce(0) { $0 + $1.amount }
    }
}

private extension Array where Element == TransactionRecord.Source {
    func sum(for addresses: [String]) -> Decimal {
        filter { source in
            addresses.contains(source.address)
        }
        .reduce(0) { $0 + $1.amount }
    }
}
