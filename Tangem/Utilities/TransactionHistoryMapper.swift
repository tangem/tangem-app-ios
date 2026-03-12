//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

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
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private let dateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
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

    func mapTransactionListItem(from records: [TransactionRecord]) -> [TransactionListItem] {
        let grouped = Dictionary(grouping: records, by: { Calendar.current.startOfDay(for: $0.date ?? Date()) })

        return grouped.sorted(by: { $0.key > $1.key }).reduce([]) { result, args in
            let (key, value) = args
            let item = TransactionListItem(
                header: dateFormatter.string(from: key),
                items: value.map(mapTransactionViewModel)
            )

            return result + [item]
        }
    }

    func mapTransactionViewModel(_ record: TransactionRecord) -> TransactionViewModel {
        var timeFormatted: String?
        if let date = record.date {
            timeFormatted = timeFormatter.string(from: date)
        }

        return TransactionViewModel(
            hash: record.hash,
            index: record.index,
            interactionAddress: interactionAddress(from: record),
            timeFormatted: timeFormatted,
            amount: transferAmount(from: record),
            isOutgoing: record.isOutgoing,
            transactionType: transactionType(from: record),
            status: status(from: record),
            isFromYieldContract: record.isFromYieldContract
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

        let amountFormatted = transferAmount(from: record)
        let date = record.date ?? Date()
        let dateFormatted = dateTimeFormatter.string(from: date)

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
    func transferAmount(from record: TransactionRecord) -> String {
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
        case "gaslessTransaction": return mapGaslessTransaction(contractMethodName: contractMethodName, transactionRecord: transactionRecord)
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

    func formatted(amount: Decimal, isOutgoing: Bool) -> String {
        let formatted = balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol)
        if amount.isZero || !showSign {
            return formatted
        }

        let prefix = isOutgoing ? AppConstants.minusSign : "+"
        return prefix + formatted
    }
}

extension TransactionHistoryMapper {
    enum Constants {
        static let maximumFractionDigits = 8
        static let roundingMode: NSDecimalNumber.RoundingMode = .down
    }
}

private extension TransactionHistoryMapper {
    func getFormattedAmount(amount: Decimal, record: TransactionRecord) -> String {
        switch transactionType(from: record) {
        case .yieldEnter, .yieldTopup, .yieldWithdraw:
            return balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol)
        case .yieldSend where record.isFromYieldContract:
            return balanceFormatter.formatCryptoBalance(amount, currencyCode: currencySymbol)
        default:
            return formatted(amount: amount, isOutgoing: record.isOutgoing)
        }
    }

    /// There are three kinds of transactions with the `gaslessTransaction` method ID:
    /// 1) Incoming — when we receive a token that was sent as a `Gasless Transaction`. We treat it as `gaslessTransfer`,
    ///    which is ultimately displayed as a generic `Operation`.
    /// 2) Outgoing — when a token is used to pay the `Gasless Transaction` fee. We classify it as `gaslessTransactionFee`,
    ///    which has its own dedicated title in the UI.
    /// 3) Outgoing — when we send a token via a `Gasless Transaction`. We treat it as `gaslessTransfer`,
    ///    which is ultimately displayed as a generic `Operation`.
    func mapGaslessTransaction(contractMethodName: String?, transactionRecord: TransactionRecord) -> TransactionViewModel.TransactionType {
        guard contractMethodName == "gaslessTransaction" else {
            assertionFailure("mapGaslessTransaction called with non-gasless transaction method")
            return .unknownOperation
        }

        guard let feeRecipient = gaslessTransactionsNetworkManager.cachedFeeRecipientAddress,
              let transfers = transactionRecord.tokenTransfers,
              transfers.contains(where: { $0.destination.caseInsensitiveCompare(feeRecipient) == .orderedSame })
        else {
            return .gaslessTransfer
        }

        return .gaslessTransactionFee
    }

    /// Ensures transactions with the "gaslessTransaction" method ID display meaningful
    /// `from` and `to` addresses in the transaction history.
    func makeGaslessTransactionInteractionAddress(from record: TransactionRecord) -> TransactionViewModel.InteractionAddressType? {
        guard case .contractMethodIdentifier(let id) = record.type,
              let name = smartContractMethodMapper.getName(for: id),
              name == "gaslessTransaction",
              let tokenTransfer = record.tokenTransfers?.first
        else {
            return nil
        }

        let destination = record.isOutgoing ? tokenTransfer.destination : tokenTransfer.source
        return .user(destination)
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
