//
//  TransactionHistoryJointOperationEnricher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

struct TransactionHistoryJointOperationEnricher {
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository

    private let currentToken: TokenItem
    private let feeTokenItem: TokenItem

    init(currentToken: TokenItem, feeTokenItem: TokenItem) {
        self.currentToken = currentToken
        self.feeTokenItem = feeTokenItem
    }

    func enrich(
        _ records: [TransactionRecord],
        with operations: [JointOperationHistoryItem],
        syntheticWindowStart: Date?
    ) -> [TransactionRecord] {
        var recordsGroupedByHash = Dictionary(grouping: records) { $0.hash.lowercased() }
        var output: [TransactionRecord] = []
        var syntheticRecords: [TransactionRecord] = []

        for operation in operations {
            if let txHash = operation.operation.txHash?.lowercased(), let matchedRecords = recordsGroupedByHash.removeValue(forKey: txHash) {
                output.append(contentsOf: takeOver(matchedRecords, by: operation))
                continue
            }

            guard let syntheticRecord = makeSyntheticRecord(from: operation, windowStart: syntheticWindowStart) else {
                continue
            }

            syntheticRecords.append(syntheticRecord)
        }

        output.append(contentsOf: recordsGroupedByHash.values.flatMap(\.self))

        return TransactionHistoryRecordsSorter.sorted(output + syntheticRecords)
    }

    // MARK: - Matched records

    private func takeOver(_ records: [TransactionRecord], by item: JointOperationHistoryItem) -> [TransactionRecord] {
        if records.contains(where: { $0.historyExtraInfo != nil }) {
            TransactionHistoryLogger.warning("A joint operation matched a record that already carries Express data, leaving it as is")
            return records
        }

        guard let anchor = anchorRecord(among: records) else {
            return records
        }

        if records.count > 1 {
            TransactionHistoryLogger.warning("A joint operation matched \(records.count) records of one hash, keeping one of them")
        }

        let transfer = innerTransfer(of: item.operation)
        let operationFee = refundFee(among: records, of: item.operation) ?? fee(of: item.operation, replacing: anchor.fee) ?? anchor.fee

        let enriched = TransactionRecord(
            hash: anchor.hash,
            index: anchor.index,
            source: transfer.map { .single(.init(address: item.safeAddress, amount: $0.amount)) } ?? anchor.source,
            destination: transfer.map { .single(.init(address: .user($0.destination), amount: $0.amount)) } ?? anchor.destination,
            fee: operationFee,
            status: backendStatus(of: item.operation.status) ?? anchor.status,
            isOutgoing: true,
            type: anchor.type,
            date: anchor.date,
            tokenTransfers: anchor.tokenTransfers,
            isFromYieldContract: anchor.isFromYieldContract,
            isFolded: anchor.isFolded,
            nonce: anchor.nonce,
            extraInfo: TransactionHistoryExtraInfo.jointOperation(JointOperationHistoryInfo(item: item))
        )

        return [enriched]
    }

    private func anchorRecord(among records: [TransactionRecord]) -> TransactionRecord? {
        let outgoingRecords = records.filter(\.isOutgoing)
        let candidates = outgoingRecords.isEmpty ? records : outgoingRecords

        return candidates.min { $0.index < $1.index }
    }

    // MARK: - Synthetic records

    private func makeSyntheticRecord(from item: JointOperationHistoryItem, windowStart: Date?) -> TransactionRecord? {
        let operation = item.operation

        guard let status = backendStatus(of: operation.status) else {
            return nil
        }

        let date = operation.finishedAt ?? item.createdAt

        if let windowStart, date < windowStart {
            return nil
        }

        let transfer = innerTransfer(of: operation)
        let amount = transfer?.amount ?? 0
        let fee = operation.status == .executed ? fee(of: operation, replacing: nil) : nil

        return TransactionRecord(
            hash: JointOperationSyntheticTxHelper(operationId: operation.id).makeSyntheticTxIdentifier(),
            index: 0,
            source: .single(.init(address: item.safeAddress, amount: amount)),
            destination: .single(.init(address: transfer.map { .user($0.destination) } ?? .user(.unknown), amount: amount)),
            fee: fee ?? feeTokenItem.zeroFee,
            status: status,
            isOutgoing: true,
            type: .contractMethodName(name: JointOperationSyntheticTxHelper.methodName),
            date: date,
            tokenTransfers: [],
            nonce: nil,
            extraInfo: TransactionHistoryExtraInfo.jointOperation(JointOperationHistoryInfo(item: item))
        )
    }

    private func backendStatus(of status: JointAccountOperationStatus) -> TransactionRecord.TransactionStatus? {
        switch status {
        case .executed:
            return .confirmed
        case .failed, .cancelled:
            return .failed
        case .awaitingSignatures, .pending, .unknown:
            return nil
        }
    }

    // MARK: - Amounts

    private func innerTransfer(of operation: JointAccountOperation) -> (destination: String, amount: Decimal)? {
        guard
            let callType = try? SafeInnerCallTypeParser.parse(try operation.safeTransaction.innerCall),
            let value = callType.value.decimal
        else {
            return nil
        }

        return (destination: callType.destination, amount: value / currentToken.decimalValue)
    }

    private func refundFee(among records: [TransactionRecord], of operation: JointAccountOperation) -> Fee? {
        let safeTransaction = operation.safeTransaction
        let refundReceiver = safeTransaction.refundReceiver

        if isWalletCurrency(safeTransaction.gasToken) {
            let refunded = records
                .filter(\.isOutgoing)
                .flatMap(\.destination.destinations)
                .filter { $0.address.string.caseInsensitiveEquals(to: refundReceiver) }
                .reduce(Decimal.zero) { $0 + $1.amount }

            return refunded > 0 ? Fee(Amount(with: currentToken.blockchain, type: currentToken.amountType, value: refunded)) : nil
        }

        guard
            !safeTransaction.gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue),
            let gasTokenItem = gasTokenItem(for: safeTransaction.gasToken)
        else {
            return nil
        }

        let refundedUnits = records
            .flatMap(\.tokenTransfers)
            .filter { transfer in
                transfer.destination.caseInsensitiveEquals(to: refundReceiver)
                    && transfer.contract?.caseInsensitiveEquals(to: safeTransaction.gasToken) == true
            }
            .reduce(Decimal.zero) { $0 + $1.amount }

        guard refundedUnits > 0 else {
            return nil
        }

        return Fee(Amount(with: gasTokenItem.blockchain, type: gasTokenItem.amountType, value: refundedUnits / gasTokenItem.decimalValue))
    }

    private func isWalletCurrency(_ gasToken: String) -> Bool {
        if gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue) {
            return currentToken.isBlockchain
        }

        return currentToken.contractAddress?.caseInsensitiveEquals(to: gasToken) == true
    }

    private func fee(of operation: JointAccountOperation, replacing currentFee: Fee?) -> Fee? {
        let safeTransaction = operation.safeTransaction

        guard let value = safeTransaction.fee.decimal else {
            return nil
        }

        let blockchain = currentToken.blockchain

        if safeTransaction.gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue) {
            return Fee(Amount(with: blockchain, value: value / blockchain.decimalValue))
        }

        if let currentFee, isPaid(currentFee, in: safeTransaction.gasToken) {
            return currentFee
        }

        guard let gasTokenItem = gasTokenItem(for: safeTransaction.gasToken) else {
            return nil
        }

        return Fee(Amount(with: gasTokenItem.blockchain, type: gasTokenItem.amountType, value: value / gasTokenItem.decimalValue))
    }

    private func gasTokenItem(for gasToken: String) -> TokenItem? {
        if currentToken.contractAddress?.caseInsensitiveEquals(to: gasToken) == true {
            return currentToken
        }

        return auxDataRepository.cryptoCurrency(forContract: gasToken, blockchain: currentToken.blockchain)
    }

    private func isPaid(_ fee: Fee, in gasToken: String) -> Bool {
        guard case .token(let token) = fee.amount.type else {
            return false
        }

        return token.contractAddress.caseInsensitiveEquals(to: gasToken)
    }
}
