//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemStaking
import TangemUI

protocol WalletModelTransactionHistoryAddressesProvider {
    var walletAddresses: [String] { get }
}

extension WalletModelTransactionHistoryAddressesProvider where Self: WalletModel {
    var walletAddresses: [String] { allAddresses.map(\.value) }
}

struct TransactionHistoryMapper {
    @Injected(\.smartContractMethodMapper) private var smartContractMethodMapper: SmartContractMethodMapper
    // Temporary: injected to obtain the gasless fee recipient address until it’s provided via app config.
    // Used to detect and classify gasless transaction fee transfers.
    @Injected(\.gaslessTransactionsNetworkManager) private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager
    @Injected(\.transactionHistoryAuxDataRepository) private var transactionHistoryAuxDataRepository: TransactionHistoryAuxDataRepository

    private let currencySymbol: String
    private let blockchain: Blockchain
    private let addressesProvider: WalletModelTransactionHistoryAddressesProvider
    private let showSign: Bool
    private let isToken: Bool

    private let stakingNetwork: StakingNetworkType?

    private var walletAddresses: [String] {
        addressesProvider.walletAddresses
    }

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
        formatter.dateStyle = .long
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

    init(
        currencySymbol: String,
        blockchain: Blockchain,
        addressesProvider: WalletModelTransactionHistoryAddressesProvider,
        showSign: Bool,
        isToken: Bool,
        stakingNetwork: StakingNetworkType?
    ) {
        self.currencySymbol = currencySymbol
        self.blockchain = blockchain
        self.addressesProvider = addressesProvider
        self.showSign = showSign
        self.isToken = isToken
        self.stakingNetwork = stakingNetwork
    }

    // [REDACTED_INFO]: when the redesign toggle is removed, drop the `DayFormatStyle`.
    func mapTransactionListItem(
        from records: [TransactionRecord],
        groupingStyle: GroupingStyle,
        dustFilter: TransactionHistoryDustFilter,
        subtitleOwnerResolver: SubtitleOwnerResolver?
    ) -> [TransactionListItem] {
        // Dust is dropped before grouping so that a fully filtered day doesn't leave an empty section behind.
        let prepared = records
            .map(prepare(_:))
            .filter {
                !dustFilter.isDust(
                    amount: $0.amount,
                    isOutgoing: $0.record.isOutgoing,
                    transactionType: $0.transactionType
                )
            }

        let mapRow = { makeTransactionViewModel(from: $0, subtitleOwnerResolver: subtitleOwnerResolver) }

        switch groupingStyle {
        case .day(let format):
            let grouped = Dictionary(grouping: prepared, by: { Calendar.current.startOfDay(for: $0.record.date ?? Date()) })

            let dateFormatter = switch format {
            case .short: Self.dateFormatter
            case .long: Self.longDateFormatter
            }

            return grouped.sorted(by: { $0.key > $1.key }).map { key, value in
                TransactionListItem(
                    header: dateFormatter.string(from: key),
                    items: value.map(mapRow)
                )
            }

        case .dayThenMonth:
            let calendar = Calendar.current
            let currentMonthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()

            let grouped = Dictionary(grouping: prepared) { prepared -> GroupingKey in
                let date = prepared.record.date ?? Date()
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
        /// All records grouped by day.
        /// - `.short`: legacy date format (e.g. "6/15/26")
        /// - `.long`: redesign date format (e.g. "June 15, 2026")
        case day(DayFormatStyle)
        /// Current-month records grouped by day; older records collapsed into month buckets.
        case dayThenMonth
    }

    enum DayFormatStyle {
        case short
        case long
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
        makeTransactionViewModel(from: prepare(record), subtitleOwnerResolver: subtitleOwnerResolver)
    }

    /// Builds the Express (swap / onramp) row subtitle: the counterparty currency (icon + symbol) with a
    /// `to:`/`from:` prefix, plus an optional " in [account/wallet]" segment when the counterparty leg lives
    /// in a different account/wallet than the viewed one. `nil` for non-Express records or when the
    /// counterparty currency can't be resolved (falls back to the default subtitle).
    private func expressSubtitle(
        from record: TransactionRecord,
        resolver: SubtitleOwnerResolver?
    ) -> TransactionDisplayModel.ExpressSubtitle? {
        switch record.expressExtraInfo {
        case .exchange(let info):
            return swapSubtitle(info: info, isOutgoing: record.isOutgoing, resolver: resolver)
        case .onramp(let info):
            return onrampSubtitle(info: info)
        case nil:
            return nil
        }
    }

    private func swapSubtitle(
        info: ExchangeTransactionInfo,
        isOutgoing: Bool,
        resolver: SubtitleOwnerResolver?
    ) -> TransactionDisplayModel.ExpressSubtitle? {
        let exchange = info.transaction

        let counterpartyCurrency: ExpressCurrency
        let counterpartyAddress: String?
        let currentLegAddress: String?
        let direction: TransactionDisplayModel.Direction

        if isOutgoing {
            counterpartyCurrency = exchange.to.currency
            counterpartyAddress = exchange.payOut.address
            currentLegAddress = exchange.fromAddress
            direction = .outgoing
        } else {
            counterpartyCurrency = exchange.from.currency
            counterpartyAddress = exchange.fromAddress
            currentLegAddress = exchange.payOut.address
            direction = .incoming
        }

        guard let counterpartyToken = info.cryptoCurrencies[counterpartyCurrency] else {
            return nil
        }

        let counterparty = counterpartyAddress.flatMap { resolver?.resolve(address: $0, blockchain: counterpartyToken.blockchain) }

        let owner = counterpartyOwner(
            counterparty: counterparty,
            currentLegAddress: currentLegAddress,
            resolver: resolver
        )

        return TransactionDisplayModel.ExpressSubtitle(
            direction: direction,
            leading: .token(TokenIconInfoBuilder().build(from: counterpartyToken, isCustom: counterpartyToken.token?.isCustom ?? false)),
            symbol: counterpartyToken.currencySymbol,
            owner: owner,
            counterparty: counterparty
        )
    }

    private func onrampSubtitle(info: OnrampTransactionInfo) -> TransactionDisplayModel.ExpressSubtitle {
        let onramp = info.transaction
        let flagURL = info.fiatCurrency?.identity.image ?? IconURLBuilder().fiatIconURL(currencyCode: onramp.from.currencyCode)

        return TransactionDisplayModel.ExpressSubtitle(
            direction: .incoming,
            leading: .fiat(url: flagURL),
            symbol: onramp.from.currencyCode,
            owner: nil,
            counterparty: nil
        )
    }

    private func counterpartyOwner(
        counterparty: TransactionViewModel.SubtitleOwner?,
        currentLegAddress: String?,
        resolver: SubtitleOwnerResolver?
    ) -> TransactionViewModel.SubtitleOwner? {
        guard
            let resolver,
            let counterpartyOwner = counterparty
        else {
            return nil
        }

        if case .unresolved = counterpartyOwner {
            return nil
        }

        let currentOwner = currentLegAddress.flatMap { resolver.resolve(address: $0, blockchain: resolver.blockchain) }
        return counterpartyOwner == currentOwner ? nil : counterpartyOwner
    }

    private func expressWarning(from record: TransactionRecord) -> TransactionViewModel.Warning? {
        switch record.expressExtraInfo {
        case .exchange(let info):
            return warning(for: info.transaction.status)
        case .onramp, nil:
            return nil
        }
    }

    private func warning(for status: ExpressTransactionStatus) -> TransactionViewModel.Warning? {
        switch status {
        case .verifying:
            return .verifying
        case .paused:
            return .paused
        case .unknown,
             .preview,
             .created,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .expired,
             .confirming,
             .exchanging,
             .sending,
             .finished,
             .failed,
             .txFailed,
             .refunded:
            return nil
        }
    }

    func mapSuggestedRecord(_ record: TransactionRecord) -> SendDestinationSuggestedTransactionRecord? {
        // Suggest address which we've already send the transaction
        guard record.isOutgoing else {
            return nil
        }

        guard !record.isFolded else {
            return nil
        }

        let type = transactionType(from: record)

        // Only simple transfer
        guard type == .transfer else {
            return nil
        }

        // For a UTXO send to self, `transferAmountValue` returns the fee rather than zero - therefore we can't use it
        let sentAmount = blockchain.isUTXO
            ? amountSentToOthers(in: record) ?? .zero
            : transferAmountValue(from: record)

        // Zero-value transfers (and sends to the wallet's own addresses as a side effect) aren't worth suggesting
        guard !sentAmount.isZero else {
            return nil
        }

        // Only for user's address
        guard case .user(let address) = interactionAddress(from: record, transactionType: type) else {
            return nil
        }

        let amountFormatted = transferAmount(from: record).legacy
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
        let legacy: String
        let redesigned: String
        /// `legacy` with the ticker after the number regardless of locale.
        let withCurrencyCode: String
    }

    struct PreparedRecord {
        let record: TransactionRecord
        let transactionType: TransactionViewModel.TransactionType
        let amount: Decimal
        let approve: TransactionRecord.TransactionType.Approve?
    }

    func prepare(_ record: TransactionRecord) -> PreparedRecord {
        let transactionType = transactionType(from: record)

        return PreparedRecord(
            record: record,
            transactionType: transactionType,
            amount: transactionType.isNetworkFee ? record.fee.amount.value : transferAmountValue(from: record),
            approve: approve(from: record)
        )
    }

    func approve(from record: TransactionRecord) -> TransactionRecord.TransactionType.Approve? {
        guard case .approve(let approve) = record.type else {
            return nil
        }

        guard needsApprovedToken(approve), let token = approvedToken(for: record) else {
            return approve
        }

        return approve.resolving(symbol: token.currencySymbol, decimals: token.decimalCount)
    }

    func needsApprovedToken(_ approve: TransactionRecord.TransactionType.Approve) -> Bool {
        switch approve.allowance {
        case .unscaled:
            return true
        case .unlimited, .revoked, .limited:
            return approve.symbol == nil
        }
    }

    func approvedToken(for record: TransactionRecord) -> TokenItem? {
        guard let contract = record.approvedTokenContract else {
            return nil
        }

        return transactionHistoryAuxDataRepository.cryptoCurrency(forContract: contract, blockchain: blockchain)
    }

    func makeTransactionViewModel(
        from prepared: PreparedRecord,
        subtitleOwnerResolver: SubtitleOwnerResolver?
    ) -> TransactionViewModel {
        let record = prepared.record

        var timeFormatted: String?
        if let date = record.date {
            timeFormatted = Self.timeFormatter.string(from: date)
        }

        let formattedAmount = getFormattedAmount(for: prepared)
        let interaction = interactionAddress(from: record, transactionType: prepared.transactionType)
        let expressSubtitle = expressSubtitle(from: record, resolver: subtitleOwnerResolver)

        return TransactionViewModel(
            hash: record.hash,
            index: record.index,
            interactionAddress: interaction,
            timeFormatted: timeFormatted,
            amount: formattedAmount.legacy,
            amountWithCurrencyCode: formattedAmount.withCurrencyCode,
            value: formattedAmount.redesigned,
            currencyCode: amountSymbol(for: prepared),
            isOutgoing: record.isOutgoing,
            transactionType: prepared.transactionType,
            status: status(from: record),
            isFromYieldContract: record.isFromYieldContract,
            subtitleOwner: expressSubtitle == nil ? subtitleOwnerResolver?.resolve(for: subtitleInteraction(from: record, fallback: interaction)) : nil,
            expressSubtitle: expressSubtitle,
            warning: expressWarning(from: record)
        )
    }

    func transferAmount(from record: TransactionRecord) -> FormattedAmount {
        getFormattedAmount(for: prepare(record))
    }

    /// An approve is sent to the contract of the token it grants, so `interactionAddress` — which the legacy
    /// row prints — names that contract. The redesigned chip names the spender instead.
    func subtitleInteraction(
        from record: TransactionRecord,
        fallback: TransactionViewModel.InteractionAddressType
    ) -> TransactionViewModel.InteractionAddressType {
        guard case .approve(let approve) = record.type else {
            return fallback
        }

        return .contract(approve.spender)
    }

    func interactionAddress(
        from record: TransactionRecord,
        transactionType: TransactionViewModel.TransactionType
    ) -> TransactionViewModel.InteractionAddressType {
        switch record.type {
        case .transfer:
            return counterpartyAddress(of: record)
        case .staking(_, let validator):
            return .staking(target: validator.map(makeStakingTarget(forAddress:)))
        default:
            return promoteToStakingTargetIfPossible(counterpartyAddress(of: record), transactionType: transactionType)
        }
    }

    private func counterpartyAddress(of record: TransactionRecord) -> TransactionViewModel.InteractionAddressType {
        record.isOutgoing
            ? mapToInteractionAddressType(destination: record.destination)
            : mapToInteractionAddressType(source: record.source)
    }

    private func promoteToStakingTargetIfPossible(
        _ interaction: TransactionViewModel.InteractionAddressType,
        transactionType: TransactionViewModel.TransactionType
    ) -> TransactionViewModel.InteractionAddressType {
        switch transactionType {
        case .stake, .unstake, .vote, .withdraw, .claimRewards, .restake, .operation, .unknownOperation:
            break
        case .transfer, .swap, .onramp, .approve, .incentiveClaim, .incentiveClaimCoin,
             .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate, .yieldSend,
             .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin,
             .gaslessTransactionFee, .gaslessTransfer, .networkFee, .tangemPay:
            return interaction
        }

        let address: String
        switch interaction {
        case .contract(let value), .user(let value):
            address = value
        case .multiple, .custom, .staking:
            return interaction
        }

        let target = makeStakingTarget(forAddress: address)

        guard target.isResolved else {
            return interaction
        }

        return .staking(target: target)
    }

    private func makeStakingTarget(forAddress address: String) -> TransactionViewModel.StakingTarget {
        guard let stakingNetwork else {
            return TransactionViewModel.StakingTarget(address: address, resolvedName: nil)
        }

        // The repository is keyed by normalized addresses, so we must normalize the address before looking it up
        let normalizedAddress = TransactionHistoryAddressNormalizer.normalize(address, networkID: stakingNetwork.rawValue)
        let target = transactionHistoryAuxDataRepository.stakingTarget(forAddress: normalizedAddress, network: stakingNetwork)

        return TransactionViewModel.StakingTarget(address: address, resolvedName: target?.name)
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
        switch record.expressExtraInfo {
        case .exchange:
            return .swap
        case .onramp:
            return .onramp
        case nil:
            break
        }

        if gaslessFeeMatcher.isNetworkFeeTransfer(record) {
            return .gaslessTransactionFee
        }

        switch record.type {
        case .transfer:
            return coinFallback(for: .transfer, record: record)
        case .contractMethodIdentifier(let id):
            let name = smartContractMethodMapper.getName(for: id)
            return transactionType(fromContractMethodName: name, transactionRecord: record)
        case .contractMethodName(let name):
            return transactionType(fromContractMethodName: name, transactionRecord: record)
        case .approve:
            return .approve
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
        let type: TransactionViewModel.TransactionType = switch contractMethodName?.nilIfEmpty {
        case "transfer": .transfer
        case "approve": .approve
        case "swap": .swap
        case "buyVoucher", "buyVoucherPOL", "delegate", "stakeETH": .stake
        case "sellVoucher_new", "sellVoucher_newPOL", "undelegate", "unstakeETH": .unstake
        case "unstakeClaimTokens_new", "unstakeClaimTokens_newPOL", "claim": .withdraw
        case "withdrawRewards", "withdrawRewardsPOL": .claimRewards
        case "redelegate": .restake
        case "yieldEnter" where !isToken: .yieldEnterCoin
        case "yieldEnter": .yieldEnter
        case "yieldClaim" where !isToken: .incentiveClaimCoin
        case "yieldClaim": .incentiveClaim
        case "yieldWithdraw" where !isToken: .yieldWithdrawCoin
        case "yieldWithdraw": .yieldWithdraw
        case "yieldReactivate": .yieldReactivate
        case "yieldTopup": .yieldTopup
        case "yieldSend": .yieldSend
        case "yieldDeploy": .yieldDeploy
        case "yieldInit": .yieldInit
        case "gaslessTransaction" where transactionRecord.isFromYieldContract: .yieldSend
        case "gaslessTransaction": .gaslessTransfer
        case .none: .unknownOperation
        case .some(let name): .operation(name: name.capitalizingFirstLetter())
        }

        return coinFallback(for: type, record: transactionRecord)
    }

    func coinFallback(
        for type: TransactionViewModel.TransactionType,
        record: TransactionRecord
    ) -> TransactionViewModel.TransactionType {
        guard !isToken else {
            return type
        }

        guard let purpose = networkFeePurpose(for: type) else {
            return type
        }

        guard
            record.isOutgoing,
            transferAmountValue(from: record).isZero,
            !GaslessTransactionFeeMatcher.isFeeCoveredByTronResources(of: record, on: blockchain)
        else {
            return type
        }

        if case .staking = promoteToStakingTargetIfPossible(counterpartyAddress(of: record), transactionType: type) {
            return type
        }

        return .networkFee(purpose: purpose, sent: sentTokens(of: record))
    }

    func networkFeePurpose(for type: TransactionViewModel.TransactionType) -> TransactionViewModel.NetworkFeePurpose? {
        switch type {
        case .transfer,
             .yieldSend:
            return .sending
        case .yieldEnterCoin:
            return .yieldMode(.activation)
        case .yieldTopup:
            return .yieldMode(.topUp)
        case .yieldWithdrawCoin:
            return .yieldMode(.deactivation)
        case .yieldDeploy:
            return .yieldMode(.deployment)
        case .yieldInit:
            return .yieldMode(.initialization)
        case .yieldReactivate:
            return .yieldMode(.reactivation)
        case .unknownOperation:
            return .operation
        case .swap,
             .onramp,
             .stake,
             .approve,
             .unstake,
             .vote,
             .withdraw,
             .claimRewards,
             .restake,
             .operation,
             .incentiveClaim,
             .incentiveClaimCoin,
             .yieldEnter,
             .yieldWithdraw,
             .gaslessTransactionFee,
             .gaslessTransfer,
             .networkFee,
             .tangemPay:
            return nil
        }
    }

    func sentTokens(of record: TransactionRecord) -> TransactionViewModel.SentTokens? {
        let sent = record.tokenTransfers.filter { transfer in
            walletAddresses.contains { $0.caseInsensitiveEquals(to: transfer.source) }
        }

        guard
            let first = sent.first,
            sent.allSatisfy({ $0.contract?.caseInsensitiveEquals(to: first.contract ?? "") ?? (first.contract == nil) })
        else {
            return nil
        }

        let resolvedToken = first.contract.flatMap {
            transactionHistoryAuxDataRepository.cryptoCurrency(forContract: $0, blockchain: blockchain)
        }

        guard
            let symbol = (resolvedToken?.currencySymbol ?? first.symbol)?.trimmed().nilIfEmpty,
            let decimals = resolvedToken?.decimalCount ?? first.decimals
        else {
            return nil
        }

        let amount = sent.reduce(Decimal.zero) { $0 + $1.amount } / pow(10, decimals)

        guard let amountText = TransactionDetailsAmountTextBuilder.build(balanceFormatter.formatDecimal(amount), symbol: symbol) else {
            return nil
        }

        let tokenItem = resolvedToken ?? makeTokenItem(for: first, symbol: symbol, decimals: decimals)
        let iconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: resolvedToken == nil)

        return .init(amount: amountText, iconInfo: iconInfo)
    }

    func makeTokenItem(
        for transfer: TransactionRecord.TokenTransfer,
        symbol: String,
        decimals: Int
    ) -> TokenItem {
        let token = Token(
            name: transfer.name ?? symbol,
            symbol: symbol,
            contractAddress: transfer.contract ?? "",
            decimalCount: decimals
        )

        return .token(token, .init(blockchain, derivationPath: nil))
    }

    func status(from record: TransactionRecord) -> TransactionViewModel.Status {
        TransactionOperationStatusMapper.viewStatus(for: record)
    }

    func formatted(amount: Decimal, isOutgoing: Bool, isFailed: Bool) -> FormattedAmount {
        let sign = showSign && !amount.isZero ? (isOutgoing ? AppConstants.minusSign : AppConstants.plusSign) : ""

        return makeFormattedAmount(
            amount,
            symbol: currencySymbol,
            sign: sign,
            redesignedSign: isFailed ? "" : sign
        )
    }

    func makeFormattedAmount(
        _ amount: Decimal,
        symbol: String,
        sign: String = "",
        redesignedSign: String? = nil
    ) -> FormattedAmount {
        let formattedAmount = balanceFormatter.formatDecimal(amount)
        let redesignedSign = redesignedSign ?? sign

        return FormattedAmount(
            legacy: sign + balanceFormatter.formatCryptoBalance(amount, currencyCode: symbol),
            redesigned: redesignedSign + formattedAmount,
            withCurrencyCode: TransactionDetailsAmountTextBuilder.build(formattedAmount, symbol: symbol, sign: redesignedSign) ?? formattedAmount
        )
    }
}

extension TransactionHistoryMapper {
    enum Constants {
        static let maximumFractionDigits = 8
        static let roundingMode: NSDecimalNumber.RoundingMode = .down
    }
}

extension TransactionHistoryMapper {
    func displayedAmountValue(from record: TransactionRecord) -> Decimal {
        prepare(record).amount
    }
}

private extension TransactionHistoryMapper {
    func transferAmountValue(from record: TransactionRecord) -> Decimal {
        if record.isOutgoing {
            if blockchain.isUTXO, let sentToOthers = amountSentToOthers(in: record) {
                return sentToOthers
            }

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

            return sent - change

        } else {
            switch record.destination {
            case .single(let destination):
                return destination.amount
            case .multiple(let destinations):
                return destinations.sum(for: walletAddresses)
            }
        }
    }

    func amountSentToOthers(in record: TransactionRecord) -> Decimal? {
        let sentToOthers = record.destination.destinations
            .filter { !walletAddresses.contains($0.address.string) }
            .reduce(Decimal.zero) { $0 + $1.amount }

        return sentToOthers.isZero ? nil : sentToOthers
    }
}

private extension TransactionHistoryMapper {
    var gaslessFeeMatcher: GaslessTransactionFeeMatcher {
        GaslessTransactionFeeMatcher(
            smartContractMethodMapper: smartContractMethodMapper,
            serviceFeeRecipientAddress: gaslessTransactionsNetworkManager.cachedFeeRecipientAddress
        )
    }
}

private extension TransactionHistoryMapper {
    func getFormattedAmount(for prepared: PreparedRecord) -> FormattedAmount {
        let record = prepared.record
        let amount = prepared.amount

        if case .onramp(let info) = record.expressExtraInfo {
            return onrampAmount(for: record, info: info, amount: amount)
        }

        switch prepared.transactionType {
        case .stake, .unstake, .restake, .vote, .withdraw:
            return makeFormattedAmount(amount, symbol: currencySymbol)
        case .approve:
            return prepared.approve.map(approveAmount(for:)) ?? makeFormattedAmount(amount, symbol: currencySymbol)
        case .yieldEnter, .yieldEnterCoin, .yieldWithdraw, .yieldWithdrawCoin:
            return makeFormattedAmount(amount, symbol: currencySymbol)
        // Supply and Withdraw take their sign from the operation rather than the on-chain direction, which
        // runs the other way: the funds leave the wallet on Supply and come back on Withdraw.
        case .yieldTopup:
            return makeFormattedAmount(
                amount,
                symbol: currencySymbol,
                redesignedSign: yieldSign(AppConstants.plusSign, amount: amount, record: record)
            )
        // Kept as a separate case so the `where` guard clearly applies only to `.yieldSend`.
        case .yieldSend where record.isFromYieldContract:
            return makeFormattedAmount(
                amount,
                symbol: currencySymbol,
                redesignedSign: yieldSign(AppConstants.minusSign, amount: amount, record: record)
            )
        default:
            return formatted(amount: amount, isOutgoing: record.isOutgoing, isFailed: record.status == .failed)
        }
    }

    func onrampAmount(for record: TransactionRecord, info: OnrampTransactionInfo, amount: Decimal) -> FormattedAmount {
        let status = status(from: record)
        let tilde = "\(AppConstants.tildeSign) "

        let redesignedSign = switch status {
        case .inProgress: tilde
        case .confirmed: AppConstants.plusSign
        case .failed, .undefined: ""
        }

        // The legacy row keeps the estimate rule it shipped with; only the redesigned sign follows the stage.
        let legacySign = info.transaction.to.actualAmount == nil || status == .inProgress ? tilde : ""

        return makeFormattedAmount(amount, symbol: currencySymbol, sign: legacySign, redesignedSign: redesignedSign)
    }

    func yieldSign(_ sign: String, amount: Decimal, record: TransactionRecord) -> String {
        guard showSign, !amount.isZero, record.status != .failed else {
            return ""
        }

        return sign
    }

    func approveAmount(for approve: TransactionRecord.TransactionType.Approve) -> FormattedAmount {
        let symbol = approveSymbol(approve)

        switch approve.allowance {
        case .revoked:
            return makeFormattedAmount(.zero, symbol: symbol)
        case .unlimited:
            let legacy = approve.symbol.map(Localization.transactionHistoryUnlimitedAmount) ?? Localization.transactionHistoryUnlimited

            return FormattedAmount(
                legacy: legacy,
                redesigned: Localization.transactionHistoryUnlimited,
                withCurrencyCode: legacy
            )
        case .limited(let value):
            return makeFormattedAmount(value, symbol: symbol)
        case .unscaled:
            return FormattedAmount(legacy: "", redesigned: "", withCurrencyCode: "")
        }
    }

    func amountSymbol(for prepared: PreparedRecord) -> String {
        prepared.approve.map(approveSymbol(_:)) ?? currencySymbol
    }

    func approveSymbol(_ approve: TransactionRecord.TransactionType.Approve) -> String {
        approve.symbol ?? ""
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
