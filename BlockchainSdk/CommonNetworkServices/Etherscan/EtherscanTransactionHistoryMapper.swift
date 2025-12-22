//
//  EtherscanTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class EtherscanTransactionHistoryMapper {
    private let blockchain: Blockchain
    private var transactionIndicesCounter: [String: Int] = [:]
    private let aaveTokens: Set<String>?

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
        aaveTokens = AAVETokenRepository.tokens(for: blockchain)
    }

    private func mapAmount(
        from transaction: EtherscanTransactionHistoryResult.Transaction,
        amountType: Amount.AmountType
    ) -> Decimal? {
        guard let transactionValue = Decimal(stringValue: transaction.value) else {
            return nil
        }

        let decimalValue: Decimal
        switch amountType {
        case .coin, .reserve, .feeResource:
            decimalValue = blockchain.decimalValue
        case .token(let value):
            decimalValue = value.decimalValue
        }

        return transactionValue / decimalValue
    }

    private func mapFee(_ transaction: EtherscanTransactionHistoryResult.Transaction) -> Fee {
        guard
            let gasUsed = Decimal(stringValue: transaction.gasUsed),
            let gasPrice = Decimal(stringValue: transaction.gasPrice)
        else {
            BSDKLogger.error(error: "Transaction with missed/invalid fee \(transaction) received")
            return Fee(.zeroCoin(for: blockchain))
        }

        let feeValue = gasUsed * gasPrice / blockchain.decimalValue
        let feeAmount = Amount(with: blockchain, value: feeValue)

        return Fee(feeAmount)
    }

    private func mapStatus(
        _ transaction: EtherscanTransactionHistoryResult.Transaction
    ) -> TransactionRecord.TransactionStatus {
        if transaction.isError?.isBooleanTrue == true {
            return .failed
        }

        if transaction.txReceiptStatus?.isBooleanTrue == true {
            return .confirmed
        }

        if let confirmations = Int(transaction.confirmations), confirmations > 0 {
            return .confirmed
        }

        return .unconfirmed
    }

    private func mapType(
        _ transaction: EtherscanTransactionHistoryResult.Transaction,
        amountType: Amount.AmountType
    ) -> TransactionRecord.TransactionType {
        switch amountType {
        case .coin where transaction.isContractInteraction,
             .token where transaction.isContractInteraction:
            if let methodId = transaction.methodId {
                return .contractMethodIdentifier(id: methodId)
            }
            let methodName = transaction.functionName?.components(separatedBy: Constants.methodNameSeparator).first?.nilIfEmpty
            if let methodName {
                return .contractMethodName(name: methodName)
            }
            // If the method name is absent in API - we fallback to the plain transfer
            return .transfer
        case .coin,
             .token,
             .reserve,
             .feeResource:
            // All other transactions are considered simple & plain transfers
            return .transfer
        }
    }

    private func mapToAPIError(_ result: EtherscanTransactionHistoryResult) -> EtherscanAPIError {
        switch result.result {
        case .description(let description) where description.lowercased().starts(with: Constants.maxRateLimitReachedResultPrefix):
            return .maxRateLimitReached
        case .transactions(let transactions) where transactions.isEmpty:
            // There is no `totalPageCount` or similar field in the Etherscan transaction history API,
            // so we determine the end of the transaction history by receiving an empty response
            return .endOfTransactionHistoryReached
        default:
            return .unknown
        }
    }

    /// Zero token transfers are most likely spam transactions, see
    /// https://polygonscan.com/tx/0x227a8dc404acb8659d87c75a2ac2427a1f86f802f2f9a8376dcfa2537a9abdf0 for example.
    private func isLikelySpamTransaction(
        amount: Decimal,
        amountType: Amount.AmountType
    ) -> Bool {
        switch amountType {
        case .token where amount.isZero:
            return true
        case .coin, .reserve, .token, .feeResource:
            return false
        }
    }
}

// MARK: - TransactionHistoryMapper protocol conformance

extension EtherscanTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: EtherscanTransactionHistoryResult,
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        guard response.status.isBooleanTrue else {
            throw mapToAPIError(response)
        }

        let transactions = response.result.transactions ?? []

        return transactions.compactMap { transaction -> TransactionRecord? in
            let sourceAddress = transaction.from
            let destinationAddress = transaction.to

            guard sourceAddress.caseInsensitiveEquals(to: walletAddress) || destinationAddress.caseInsensitiveEquals(to: walletAddress) else {
                BSDKLogger.error(error: "Unrelated transaction \(transaction) received")
                return nil
            }

            guard let transactionAmount = mapAmount(from: transaction, amountType: amountType) else {
                BSDKLogger.error(error: "Transaction with invalid value \(transaction) received")
                return nil
            }

            if isLikelySpamTransaction(amount: transactionAmount, amountType: amountType) {
                return nil
            }

            let isOutgoing = sourceAddress.caseInsensitiveEquals(to: walletAddress)

            let source = TransactionRecord.Source(
                address: sourceAddress,
                amount: transactionAmount
            )

            let destinationAddressType: TransactionRecord.Destination.Address = {
                if let contract = transaction.contractAddress?.nilIfEmpty {
                    return .contract(contract)
                }

                if transaction.functionName?.nilIfEmpty != nil {
                    return .contract(destinationAddress)
                }

                return .user(destinationAddress)
            }()

            let destination: TransactionRecord.Destination = .init(address: destinationAddressType, amount: transactionAmount)

            guard let timeStamp = TimeInterval(transaction.timeStamp) else {
                BSDKLogger.error(error: "Transaction with invalid timeStamp \(transaction) received")
                return nil
            }

            let index = transactionIndicesCounter[transaction.hash, default: 0]
            transactionIndicesCounter[transaction.hash] = index + 1

            let isFromYieldContract = aaveTokens?.contains(transaction.from.lowercased()) ?? false

            return TransactionRecord(
                hash: transaction.hash,
                index: index,
                source: .single(source),
                destination: .single(destination),
                fee: mapFee(transaction),
                status: mapStatus(transaction),
                isOutgoing: isOutgoing,
                type: mapType(transaction, amountType: amountType),
                date: Date(timeIntervalSince1970: timeStamp),
                isFromYieldContract: isFromYieldContract
            )
        }
    }

    func reset() {
        transactionIndicesCounter.removeAll()
    }
}

// MARK: - Constants

private extension EtherscanTransactionHistoryMapper {
    enum Constants {
        static let maxRateLimitReachedResultPrefix = "max rate limit reached"
        /// Method names in the API look like `swap(address executor,tuple desc,bytes permit,bytes data)`,
        /// so we have to remove all method signatures (parameters, types, etc).
        static let methodNameSeparator = "("
    }
}

// MARK: - Convenience extensions

private extension EtherscanTransactionHistoryResult.Transaction {
    var isContractInteraction: Bool {
        return contractAddress?.nilIfEmpty != nil || functionName?.nilIfEmpty != nil
    }
}

private extension EtherscanTransactionHistoryResult.Result {
    var transactions: [EtherscanTransactionHistoryResult.Transaction]? {
        if case .transactions(let transactions) = self {
            return transactions
        }

        return nil
    }

    var description: String? {
        if case .description(let description) = self {
            return description
        }

        return nil
    }
}

private extension String {
    var isBooleanTrue: Bool {
        return Int(self) == 1
    }
}
