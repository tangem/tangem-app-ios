//
//  TronTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class TronTransactionHistoryMapper {
    private let blockchain: Blockchain
    private var transactionIndicesCounter: [String: Int] = [:]

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    private func extractTransactions(
        from response: BlockBookAddressResponse,
        amountType: Amount.AmountType
    ) -> [BlockBookAddressResponse.Transaction] {
        guard let transactions = response.transactions else {
            return []
        }

        // Filter technical Tron gasless transactions.
        let filteredTransactions = transactions.filter { transaction in
            guard let contractType = contractType(transaction) else {
                return true
            }

            return !Constants.excludedContractTypes.contains(contractType)
        }

        switch amountType {
        case .coin, .reserve, .feeResource:
            return filteredTransactions
        case .token(let value):
            // Another fix for a horrible Tron Blockbook API: sometimes API returns transaction history
            // from another token for a particular token if this token doesn't have transaction history yet
            //
            // Here we're filtering out unrelated transaction history completely if needed
            guard
                let tokens = response.tokens,
                tokens.contains(where: { $0.matching(contractAddress: value.contractAddress) })
            else {
                return []
            }

            return filteredTransactions
        }
    }

    /// Extracts the transaction info for a `coin` transfer.
    private func extractTransactionInfo(
        from transaction: BlockBookAddressResponse.Transaction,
        sourceAddress: String,
        destinationAddress: String,
        walletAddress: String,
        votes: [Vote]
    ) -> TransactionInfo? {
        guard
            sourceAddress.caseInsensitiveEquals(to: walletAddress) || destinationAddress.caseInsensitiveEquals(to: walletAddress)
        else {
            BSDKLogger.error(error: "Unrelated transaction \(transaction) received")
            return nil
        }

        guard let transactionAmount = transactionAmount(of: transaction, votes: votes) else {
            BSDKLogger.error(error: "Transaction with invalid value \(transaction) received")
            return nil
        }

        let isOutgoing = sourceAddress.caseInsensitiveEquals(to: walletAddress)

        let source = TransactionRecord.Source(
            address: sourceAddress,
            amount: transactionAmount
        )

        let destination = TransactionRecord.Destination(
            address: isContractInteraction(transaction) ? .contract(destinationAddress) : .user(destinationAddress),
            amount: transactionAmount
        )

        return TransactionInfo(
            source: source,
            destination: destination,
            isOutgoing: isOutgoing
        )
    }

    private func isContractInteraction(_ transaction: BlockBookAddressResponse.Transaction) -> Bool {
        if let contractType = transaction.contractType {
            return contractType != TronContractType.transferContractType.rawValue
        }

        return transaction.chainExtraData.flatMap(extraDataContractType(from:)) == .triggerSmartContract
    }

    private static func votes(of transaction: BlockBookAddressResponse.Transaction) -> [Vote] {
        if let votes = transaction.chainExtraData?.payload?.votes {
            return votes.map { Vote(witness: $0.address, count: $0.count) }
        }

        guard let voteList = transaction.voteList else {
            return []
        }

        return voteList.sorted { $0.key < $1.key }.map { Vote(witness: $0.key, count: String($0.value)) }
    }

    private func transactionAmount(of transaction: BlockBookAddressResponse.Transaction, votes: [Vote]) -> Decimal? {
        if votes.isNotEmpty {
            // A vote is backed by one frozen TRX, so the counts arrive in whole TRX rather than in sun.
            return votes.reduce(Decimal.zero) { total, vote in
                total + (vote.count.flatMap { Decimal(string: $0) } ?? .zero)
            }
        }

        let payload = transaction.chainExtraData?.payload

        if let claimedReward = payload?.claimedVoteReward.flatMap({ Decimal(string: $0) }) {
            return claimedReward / blockchain.decimalValue
        }

        return Decimal(string: transaction.value).map { $0 / blockchain.decimalValue }
    }

    /// Nownodes reports the transaction's own `fees` as zero for every Tron transaction and delivers the
    /// charged amount in the contract payload instead, so the payload wins whenever it carries one.
    private func transactionFee(of transaction: BlockBookAddressResponse.Transaction) -> Decimal? {
        if let totalFee = transaction.chainExtraData?.payload?.totalFee, let fee = Decimal(stringValue: totalFee) {
            return fee
        }

        return Decimal(stringValue: transaction.fees)
    }

    /// Extracts the transaction info for a `token` transfer.
    private func extractTransactionInfos(
        from tokenTransfers: [BlockBookAddressResponse.TokenTransfer],
        token: Token,
        walletAddress: String,
        isOutgoing: Bool
    ) -> [TransactionInfo] {
        // Double check to exclude token transfers sent to self.
        // Actually, this is a feasible case, but we don't support such transfers at the moment
        let filteredTokenTransfers = tokenTransfers.filter { transfer in
            if isOutgoing {
                return transfer.from.caseInsensitiveEquals(to: walletAddress) && !transfer.to.caseInsensitiveEquals(to: walletAddress)
            }
            return transfer.to.caseInsensitiveEquals(to: walletAddress) && !transfer.from.caseInsensitiveEquals(to: walletAddress)
        }

        let otherAddresses: [String]
        let groupedFilteredTokenTransfers: [String: [BlockBookAddressResponse.TokenTransfer]]

        if isOutgoing {
            otherAddresses = filteredTokenTransfers.uniqueProperties(\.to)
            groupedFilteredTokenTransfers = filteredTokenTransfers.grouped(by: \.to)
        } else {
            otherAddresses = filteredTokenTransfers.uniqueProperties(\.from)
            groupedFilteredTokenTransfers = filteredTokenTransfers.grouped(by: \.from)
        }

        return otherAddresses.reduce(into: []) { partialResult, otherAddress in
            let transfers = groupedFilteredTokenTransfers[otherAddress, default: []]

            partialResult += transfers.compactMap { transfer in
                guard
                    let rawValue = transfer.value,
                    let value = Decimal(string: rawValue)
                else {
                    BSDKLogger.error(error: "Token transfer \(transfer) with invalid value received")
                    return nil
                }

                let transactionAmount = value / token.decimalValue

                let source = TransactionRecord.Source(
                    address: isOutgoing ? walletAddress : otherAddress,
                    amount: transactionAmount
                )

                let destination = TransactionRecord.Destination(
                    address: .user(isOutgoing ? otherAddress : walletAddress),
                    amount: transactionAmount
                )

                return TransactionInfo(
                    source: source,
                    destination: destination,
                    isOutgoing: isOutgoing
                )
            }
        }
    }

    private func mapToTransactionRecords(
        transaction: BlockBookAddressResponse.Transaction,
        transactionInfos: [TransactionInfo],
        amountType: Amount.AmountType,
        fees: Decimal,
        votes: [Vote],
        tokens: [BlockBookAddressResponse.Token]?
    ) -> [TransactionRecord] {
        // Nownodes appends `0x` prefixes to TRON txids, so we have to strip these prefixes
        let hash = transaction.txid.removeHexPrefix()
        let fee = Fee(Amount(with: blockchain, value: fees / blockchain.decimalValue))
        let date = Date(timeIntervalSince1970: TimeInterval(transaction.blockTime))
        let status = status(transaction)
        let type = transactionType(transaction, amountType: amountType, votes: votes, tokens: tokens)
        let tokenTransfers = tokenTransfers(transaction, tokens: tokens)

        return transactionInfos.map { transactionInfo in
            let index = transactionIndicesCounter[hash, default: 0]
            transactionIndicesCounter[hash] = index + 1

            let destination: TransactionRecord.Destination = {
                switch type {
                case .staking(let stakingType, _):
                    switch stakingType {
                    case .stake, .unstake, .vote:
                        // All three are self-addressed (source == destination == own address), and the displayed
                        // amount is computed downstream as "sent − change returned to self". Leaving the staked
                        // TRX — or, for a vote, the number of votes cast — on the destination would count it as
                        // change and net the amount to zero, so the destination keeps its address and gives up
                        // its amount.
                        return TransactionRecord.Destination(address: transactionInfo.destination.address, amount: 0)
                    case .withdraw, .claimRewards:
                        return transactionInfo.destination
                    case .restake:
                        // Never produced by this mapper: no TRON contract type maps to it.
                        return transactionInfo.destination
                    }
                case .transfer, .contractMethodIdentifier, .contractMethodName, .approve:
                    return transactionInfo.destination
                }
            }()

            // Withdraw/claim move TRX back to the account, but on-chain they are owner-initiated,
            // so the generic "source == wallet" rule would wrongly classify them as outgoing.
            let isOutgoing: Bool = {
                switch type {
                case .staking(.withdraw, _), .staking(.claimRewards, _):
                    return false
                default:
                    return transactionInfo.isOutgoing
                }
            }()

            return TransactionRecord(
                hash: hash,
                index: index,
                source: .single(transactionInfo.source),
                destination: .single(destination),
                fee: fee,
                status: status,
                isOutgoing: isOutgoing,
                type: type,
                date: date,
                tokenTransfers: tokenTransfers,
                nonce: nil
            )
        }
    }

    private func status(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionStatus {
        switch transaction.tronTXReceipt?.status {
        case .failure:
            return .failed
        case .ok:
            return .confirmed
        case .pending:
            return .unconfirmed
        case .none:
            return transaction.confirmations > 0 ? .confirmed : .unconfirmed
        }
    }

    private func transactionType(
        _ transaction: BlockBookAddressResponse.Transaction,
        amountType: Amount.AmountType,
        votes: [Vote],
        tokens: [BlockBookAddressResponse.Token]?
    ) -> TransactionRecord.TransactionType {
        switch amountType {
        case .coin:
            // NowNodes may omit the integer `contract_type` field and instead deliver the transaction
            // type via the `chainExtraData` payload. Fall back to that payload in such cases.
            guard let contractTypeInt = transaction.contractType,
                  let contractType = TronContractType(rawValue: contractTypeInt) else {
                return transactionType(fromChainExtraDataOf: transaction, votes: votes, tokens: tokens)
            }

            switch contractType {
            case .transferContractType,
                 .transferAssetContractType:
                return .transfer
            case .triggerSmartContractType:
                return contractCallType(transaction, tokens: tokens) ?? .contractMethodIdentifier(id: transaction.contractName ?? .unknown)
            case .voteWitnessContractType:
                return .staking(type: .vote, target: votes.first?.witness)
            case .withdrawExpireUnfreezeContractType:
                return .staking(type: .withdraw, target: nil)
            case .freezeBalanceV2ContractType:
                return .staking(type: .stake, target: nil)
            case .unfreezeBalanceV2ContractType:
                return .staking(type: .unstake, target: nil)
            case .withdrawBalanceContractType:
                return .staking(type: .claimRewards, target: nil)
            default:
                return .contractMethodIdentifier(id: transaction.contractName ?? .unknown)
            }
        default:
            // All TRC10 and TRC20 token transactions are considered simple & plain transfers
            return .transfer
        }
    }

    /// Extracts the coin transaction type from the `chainExtraData` payload, which NowNodes started
    /// delivering instead of the integer `contract_type` field. The contract type arrives as a string.
    private func transactionType(
        fromChainExtraDataOf transaction: BlockBookAddressResponse.Transaction,
        votes: [Vote],
        tokens: [BlockBookAddressResponse.Token]?
    ) -> TransactionRecord.TransactionType {
        guard
            let chainExtraData = transaction.chainExtraData,
            let contractType = extraDataContractType(from: chainExtraData)
        else {
            return .transfer
        }

        switch contractType {
        case .transferContract:
            return .transfer
        case .triggerSmartContract:
            return contractCallType(transaction, tokens: tokens) ?? .transfer
        case .voteWitnessContract:
            return .staking(type: .vote, target: votes.first?.witness)
        case .withdrawBalanceContract:
            return .staking(type: .claimRewards, target: nil)
        case .freezeBalanceV2Contract:
            return .staking(type: .stake, target: nil)
        case .unfreezeBalanceV2Contract:
            return .staking(type: .unstake, target: nil)
        case .withdrawExpireUnfreezeContract:
            return .staking(type: .withdraw, target: nil)
        // Following contract types are filtered at the beginning, they must not appear.
        // Handled to have exhaustive switch.
        case .accountCreateContract, .delegateResourceContract, .unDelegateResourceContract:
            #if INTERNAL || DEBUG
            preconditionFailure()
            #else
            return .transfer
            #endif
        }
    }

    private func contractCallType(
        _ transaction: BlockBookAddressResponse.Transaction,
        tokens: [BlockBookAddressResponse.Token]?
    ) -> TransactionRecord.TransactionType? {
        guard let methodId = transaction.ethereumSpecific?.methodId else {
            return nil
        }

        if methodId.caseInsensitiveEquals(to: TransferERC20TokenMethod.methodId) {
            return .transfer
        }

        if methodId.caseInsensitiveEquals(to: ApproveERC20TokenMethod.methodId), let approve = approve(transaction, tokens: tokens) {
            return .approve(approve)
        }

        return .contractMethodIdentifier(id: methodId)
    }

    private func approve(
        _ transaction: BlockBookAddressResponse.Transaction,
        tokens: [BlockBookAddressResponse.Token]?
    ) -> TransactionRecord.TransactionType.Approve? {
        guard
            let calldata = transaction.ethereumSpecific?.data,
            let call = TronTokenApproveCallData(calldata: calldata)
        else {
            return nil
        }

        let token = transaction.destinationAddress.flatMap { contract in
            tokens?.first { $0.matching(contractAddress: contract) }
        }

        return ApproveHistoryMapper.approve(spender: call.spender, amount: call.amount, symbol: token?.symbol, decimals: token?.decimals)
    }

    private func contractType(_ transaction: BlockBookAddressResponse.Transaction) -> TronContractType? {
        if let contractTypeInt = transaction.contractType {
            return TronContractType(rawValue: contractTypeInt)
        } else {
            guard let chainExtraData = transaction.chainExtraData else { return nil }

            let extraDataContractType = extraDataContractType(from: chainExtraData)
            let contractType = extraDataContractType?.toTronContractType()
            return contractType
        }
    }

    private func extraDataContractType(from chainExtraData: BlockBookAddressResponse.ChainExtraData) -> TronChainExtraDataContractType? {
        guard chainExtraData.payloadType == Constants.tronPayloadType else {
            return nil
        }

        let rawContractType = chainExtraData.payload?.contractType
        return TronChainExtraDataContractType(rawValue: rawContractType ?? .unknown)
    }

    private func tokenTransfers(
        _ transaction: BlockBookAddressResponse.Transaction,
        tokens: [BlockBookAddressResponse.Token]?
    ) -> [TransactionRecord.TokenTransfer] {
        guard let tokenTransfers = transaction.tokenTransfers?.nilIfEmpty else {
            return decodedTokenTransfer(transaction, tokens: tokens).map { [$0] } ?? []
        }

        return tokenTransfers.map { transfer -> TransactionRecord.TokenTransfer in
            let amount = Decimal(stringValue: transfer.value) ?? 0
            return TransactionRecord.TokenTransfer(
                source: transfer.from,
                destination: transfer.to,
                amount: amount,
                name: transfer.name,
                symbol: transfer.symbol,
                decimals: transfer.decimals,
                contract: transfer.compat.contract
            )
        }
    }

    private func decodedTokenTransfer(
        _ transaction: BlockBookAddressResponse.Transaction,
        tokens: [BlockBookAddressResponse.Token]?
    ) -> TransactionRecord.TokenTransfer? {
        guard
            let calldata = transaction.ethereumSpecific?.data,
            let transfer = TronTokenTransferCallData(calldata: calldata),
            let amount = Decimal(stringValue: transfer.amount.description),
            let source = transaction.sourceAddress,
            let contract = transaction.destinationAddress
        else {
            return nil
        }

        let token = tokens?.first { $0.matching(contractAddress: contract) }

        return TransactionRecord.TokenTransfer(
            source: source,
            destination: transfer.recipient,
            amount: amount,
            name: nil,
            symbol: token?.symbol,
            decimals: token?.decimals,
            contract: contract
        )
    }
}

// MARK: - TransactionHistoryMapper protocol conformance

extension TronTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: BlockBookAddressResponse,
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        let transactions = extractTransactions(from: response, amountType: amountType)
        let walletAddress = response.address

        return transactions
            .reduce(into: []) { partialResult, transaction in
                guard
                    let sourceAddress = transaction.sourceAddress,
                    let fees = transactionFee(of: transaction)
                else {
                    BSDKLogger.error(error: "Transaction \(transaction) doesn't contain a required information")
                    return
                }

                // Operations that send nothing anywhere — voting for a witness, claiming rewards — carry no
                // recipient in the Blockbook payload. They act on the account itself, so it stands in as the
                // destination; requiring one would drop those transactions from the history entirely.
                let destinationAddress = transaction.destinationAddress ?? walletAddress
                let votes = Self.votes(of: transaction)

                switch amountType {
                case .coin, .reserve, .feeResource:
                    if let transactionInfo = extractTransactionInfo(
                        from: transaction,
                        sourceAddress: sourceAddress,
                        destinationAddress: destinationAddress,
                        walletAddress: walletAddress,
                        votes: votes
                    ) {
                        partialResult += mapToTransactionRecords(
                            transaction: transaction,
                            transactionInfos: [transactionInfo],
                            amountType: amountType,
                            fees: fees,
                            votes: votes,
                            tokens: response.tokens
                        )
                    }
                case .token(let token):
                    if let transfers = transaction.tokenTransfers, !transfers.isEmpty {
                        let outgoingTransactionInfos = extractTransactionInfos(
                            from: transfers,
                            token: token,
                            walletAddress: walletAddress,
                            isOutgoing: true
                        )
                        let incomingTransactionInfos = extractTransactionInfos(
                            from: transfers,
                            token: token,
                            walletAddress: walletAddress,
                            isOutgoing: false
                        )
                        partialResult += mapToTransactionRecords(
                            transaction: transaction,
                            transactionInfos: outgoingTransactionInfos + incomingTransactionInfos,
                            amountType: amountType,
                            fees: fees,
                            votes: votes,
                            tokens: response.tokens
                        )
                    }
                }
            }
    }

    func reset() {
        transactionIndicesCounter.removeAll()
    }
}

// MARK: - BlockBookTransactionHistoryTotalPageCountExtractor protocol conformance

extension TronTransactionHistoryMapper: BlockBookTransactionHistoryTotalPageCountExtractor {
    func extractTotalPageCount(from response: BlockBookAddressResponse, contractAddress: String?) throws -> Int {
        // If transaction history is requested for a TRC20 token - `totalPageCount` must be calculated manually
        // using `$.tokens[*].transfers` and `$.itemsOnPage` DTO fields because `$.totalPages` DTO field always
        // contains the number of pages for the TRX (Tron coin) transaction history for a given address
        //
        // If there is no transaction history for a particular TRC20 token - the `response.tokens` field
        // does not exist or is empty; in such cases we consider the transaction history empty (`totalPageCount` equals 0)
        if let contractAddress {
            guard
                let itemsOnPage = response.itemsOnPage,
                let tokens = response.tokens,
                let token = tokens.first(where: { $0.matching(contractAddress: contractAddress) }),
                let transfersCount = token.transfers
            else {
                return 0
            }

            return Int(ceil(Double(transfersCount) / Double(itemsOnPage)))
        }

        return response.totalPages ?? 0
    }
}

// MARK: - Convenience types

private extension TronTransactionHistoryMapper {
    /// Intermediate model for simpler mapping.
    struct TransactionInfo {
        let source: TransactionRecord.Source
        let destination: TransactionRecord.Destination
        let isOutgoing: Bool
    }

    struct Vote {
        let witness: String?
        let count: String?
    }

    /// See https://github.com/tronprotocol/documentation/blob/master/English_Documentation/TRON_Virtual_Machine/TRC10_TRX_TRANSFER_INTRODUCTION_FOR_EXCHANGES.md
    /// and https://github.com/tronprotocol/protocol/blob/master/English%20version%20of%20TRON%20Protocol%20document.md for reference
    /// - Note: Only a small subset of existing contact types are represented in this enum.
    enum TronContractType: Int {
        /// Tron transfers.
        case transferContractType = 1
        /// TRC10 token transfers.
        case transferAssetContractType = 2
        case voteWitnessContractType = 4
        case accountCreateContractType = 9
        case withdrawBalanceContractType = 13
        /// TRC20 token transfers.
        case triggerSmartContractType = 31
        case freezeBalanceV2ContractType = 54
        case unfreezeBalanceV2ContractType = 55
        case withdrawExpireUnfreezeContractType = 56
        case delegateResourceContractType = 57
        case unDelegateResourceContractType = 58
    }

    /// Contract types delivered as strings via `chainExtraData.payload.contractType` (NowNodes V2 contract),
    /// used when the integer `contract_type` field is absent.
    enum TronChainExtraDataContractType: String {
        case transferContract = "TransferContract"
        case triggerSmartContract = "TriggerSmartContract"
        case voteWitnessContract = "VoteWitnessContract"
        case freezeBalanceV2Contract = "FreezeBalanceV2Contract"
        case unfreezeBalanceV2Contract = "UnfreezeBalanceV2Contract"
        case withdrawBalanceContract = "WithdrawBalanceContract"
        case withdrawExpireUnfreezeContract = "WithdrawExpireUnfreezeContract"
        case accountCreateContract = "AccountCreateContract"
        case delegateResourceContract = "DelegateResourceContract"
        case unDelegateResourceContract = "UnDelegateResourceContract"

        func toTronContractType() -> TronContractType? {
            switch self {
            case .transferContract:
                return .transferContractType
            case .triggerSmartContract:
                return .triggerSmartContractType
            case .voteWitnessContract:
                return .voteWitnessContractType
            case .freezeBalanceV2Contract:
                return .freezeBalanceV2ContractType
            case .unfreezeBalanceV2Contract:
                return .unfreezeBalanceV2ContractType
            case .withdrawBalanceContract:
                return .withdrawBalanceContractType
            case .withdrawExpireUnfreezeContract:
                return .withdrawExpireUnfreezeContractType
            case .accountCreateContract:
                return .accountCreateContractType
            case .delegateResourceContract:
                return .delegateResourceContractType
            case .unDelegateResourceContract:
                return .unDelegateResourceContractType
            }
        }
    }

    enum Constants {
        static let tronPayloadType = "tron"
        static let excludedContractTypes: Set<TronContractType> = [
            TronContractType.accountCreateContractType,
            TronContractType.delegateResourceContractType,
            TronContractType.unDelegateResourceContractType,
        ]
    }
}

// MARK: - Convenience extensions

private extension BlockBookAddressResponse.Token {
    func matching(contractAddress: String) -> Bool {
        // Tron Blockbook has a really terrible API contract: a token's contract address may be stored in various DTO fields,
        // not just in the `$.tokens[*].contract` field
        let props = [
            id,
            name,
            contract,
        ]

        return props
            .compactMap { $0?.caseInsensitiveEquals(to: contractAddress) }
            .contains(true)
    }
}

private extension BlockBookAddressResponse.Transaction {
    /// NowNodes changed the Tron Blockbook API contract: the dedicated `fromAddress`/`toAddress` fields
    /// may now be absent, in which case the addresses are delivered via the `vin`/`vout` arrays (as in
    /// other Blockbook-based networks like Bitcoin or Ethereum). Fall back to those fields when the
    /// dedicated ones are missing.
    var sourceAddress: String? {
        fromAddress ?? compat.vin.first?.addresses?.first
    }

    var destinationAddress: String? {
        toAddress ?? compat.vout.first?.addresses?.first
    }
}
