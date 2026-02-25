//
//  SolanaTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class SolanaTransactionHistoryMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

extension SolanaTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: [SolanaTransactionHistoryDTO.TransactionDetails],
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> [TransactionRecord] {
        response.compactMap { transaction in
            mapToTransactionRecord(
                transaction: transaction,
                walletAddress: walletAddress,
                amountType: amountType
            )
        }
    }
}

private extension SolanaTransactionHistoryMapper {
    enum TransactionKind {
        case transfer(instruction: SolanaTransactionHistoryDTO.Instruction)
        case tokenOperation(instruction: SolanaTransactionHistoryDTO.Instruction?)
        case otherOperation
    }

    enum Constants {
        static let systemProgramId = "11111111111111111111111111111111"
        static let computeBudgetProgramId = "ComputeBudget111111111111111111111111111111"
        static let tokenProgram = "spl-token"
        static let transferType = "transfer"
        static let transferCheckedType = "transferChecked"
        static let operationType = "operation"
    }

    func mapToTransactionRecord(
        transaction: SolanaTransactionHistoryDTO.TransactionDetails,
        walletAddress: String,
        amountType: Amount.AmountType
    ) -> TransactionRecord? {
        guard let hash = transaction.transaction.signatures.first else {
            return nil
        }

        let instructions = allInstructions(in: transaction)
        let kind = classifyTransaction(transaction: transaction, instructions: instructions)

        let amountDelta: Decimal
        let sourceAddress: String
        let destinationAddress: String

        switch amountType {
        case .coin, .reserve:
            amountDelta = solDelta(transaction: transaction, walletAddress: walletAddress)
            if amountDelta == 0 {
                return nil
            }

            switch kind {
            case .transfer(let instruction):
                let parsedInfo = instruction.parsed?.info
                sourceAddress = parsedInfo?.source ?? walletAddress
                destinationAddress = parsedInfo?.destination ?? fallbackCounterpartyAddress(
                    accountKeys: transaction.transaction.message.accountKeys,
                    walletAddress: walletAddress
                )
            case .tokenOperation:
                let counterparty = fallbackCounterpartyAddress(
                    accountKeys: transaction.transaction.message.accountKeys,
                    walletAddress: walletAddress
                )
                sourceAddress = amountDelta < 0 ? walletAddress : counterparty
                destinationAddress = amountDelta < 0 ? counterparty : walletAddress
            case .otherOperation:
                let counterparty = fallbackCounterpartyAddress(
                    accountKeys: transaction.transaction.message.accountKeys,
                    walletAddress: walletAddress
                )
                sourceAddress = amountDelta < 0 ? walletAddress : counterparty
                destinationAddress = amountDelta < 0 ? counterparty : walletAddress
            }
        case .token(let token):
            amountDelta = tokenDelta(
                transaction: transaction,
                walletAddress: walletAddress,
                mint: token.contractAddress
            )
            if amountDelta == 0 {
                return nil
            }

            let tokenInstruction: SolanaTransactionHistoryDTO.Instruction? = {
                if case .tokenOperation(let instruction) = kind {
                    return instruction
                }
                return nil
            }()

            let parsedInfo = tokenInstruction?.parsed?.info
            let counterparty = fallbackCounterpartyAddress(
                accountKeys: transaction.transaction.message.accountKeys,
                walletAddress: walletAddress
            )
            sourceAddress = amountDelta < 0 ? (parsedInfo?.source ?? walletAddress) : (parsedInfo?.source ?? counterparty)
            destinationAddress = amountDelta < 0 ? (parsedInfo?.destination ?? counterparty) : (parsedInfo?.destination ?? walletAddress)
        case .feeResource:
            return nil
        }

        let absoluteAmount = amountDelta.magnitude
        let isOutgoing = amountDelta < 0
        let status: TransactionRecord.TransactionStatus = (transaction.meta?.err == nil) ? .confirmed : .failed

        let feeValue = Decimal(transaction.meta?.fee ?? 0) / blockchain.decimalValue
        let fee = Fee(Amount(with: blockchain, value: feeValue))

        let recordType: TransactionRecord.TransactionType = {
            switch kind {
            case .transfer:
                return .transfer
            case .tokenOperation, .otherOperation:
                return .contractMethodName(name: Constants.operationType)
            }
        }()

        let source = TransactionRecord.Source(
            address: sourceAddress,
            amount: absoluteAmount
        )
        let destination = TransactionRecord.Destination(
            address: .user(destinationAddress),
            amount: absoluteAmount
        )

        return TransactionRecord(
            hash: hash,
            index: 0,
            source: .single(source),
            destination: .single(destination),
            fee: fee,
            status: status,
            isOutgoing: isOutgoing,
            type: recordType,
            date: transaction.blockTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
    }

    func allInstructions(in transaction: SolanaTransactionHistoryDTO.TransactionDetails) -> [SolanaTransactionHistoryDTO.Instruction] {
        let outerInstructions = transaction.transaction.message.instructions
        let innerInstructions = transaction.meta?.innerInstructions.flatMap(\.instructions) ?? []
        return outerInstructions + innerInstructions
    }

    func classifyTransaction(
        transaction: SolanaTransactionHistoryDTO.TransactionDetails,
        instructions: [SolanaTransactionHistoryDTO.Instruction]
    ) -> TransactionKind {
        let onlyTransferPrograms = instructions.allSatisfy { instruction in
            let programId = instruction.programId
            return programId == Constants.systemProgramId || programId == Constants.computeBudgetProgramId
        }

        let transferInstruction = instructions.first {
            $0.programId == Constants.systemProgramId && $0.parsed?.type == Constants.transferType
        }

        let hasTokenInstruction = instructions.contains { instruction in
            guard instruction.program == Constants.tokenProgram else {
                return false
            }

            let operationType = instruction.parsed?.type
            return operationType == Constants.transferType || operationType == Constants.transferCheckedType
        }

        let tokenInstruction = instructions.first { instruction in
            guard instruction.program == Constants.tokenProgram else {
                return false
            }

            let operationType = instruction.parsed?.type
            return operationType == Constants.transferType || operationType == Constants.transferCheckedType
        }

        let hasTransferShape =
            (transaction.meta?.innerInstructions.isEmpty ?? true) &&
            (transaction.meta?.preTokenBalances.isEmpty ?? true) &&
            (transaction.meta?.postTokenBalances.isEmpty ?? true) &&
            (transaction.meta?.rewards.isEmpty ?? true) &&
            onlyTransferPrograms &&
            (transferInstruction != nil)

        if hasTransferShape, let transferInstruction {
            return .transfer(instruction: transferInstruction)
        }

        if hasTokenInstruction {
            return .tokenOperation(instruction: tokenInstruction)
        }

        return .otherOperation
    }

    func solDelta(
        transaction: SolanaTransactionHistoryDTO.TransactionDetails,
        walletAddress: String
    ) -> Decimal {
        let accountKeys = transaction.transaction.message.accountKeys
        guard let index = accountKeys.firstIndex(where: {
            $0.pubkey.caseInsensitiveEquals(to: walletAddress)
        }) else {
            return 0
        }

        let preBalances = transaction.meta?.preBalances ?? []
        let postBalances = transaction.meta?.postBalances ?? []
        guard preBalances.indices.contains(index), postBalances.indices.contains(index) else {
            return 0
        }

        let pre = Decimal(preBalances[index])
        let post = Decimal(postBalances[index])
        return (post - pre) / blockchain.decimalValue
    }

    func tokenDelta(
        transaction: SolanaTransactionHistoryDTO.TransactionDetails,
        walletAddress: String,
        mint: String
    ) -> Decimal {
        let preBalances = aggregateTokenBalances(
            transaction.meta?.preTokenBalances ?? [],
            walletAddress: walletAddress
        )
        let postBalances = aggregateTokenBalances(
            transaction.meta?.postTokenBalances ?? [],
            walletAddress: walletAddress
        )

        return postBalances[mint, default: 0] - preBalances[mint, default: 0]
    }

    func aggregateTokenBalances(
        _ balances: [SolanaTransactionHistoryDTO.TransactionDetails.Meta.TokenBalance],
        walletAddress: String
    ) -> [String: Decimal] {
        balances.reduce(into: [:]) { partialResult, balance in
            guard
                let owner = balance.owner,
                owner.caseInsensitiveEquals(to: walletAddress),
                let mint = balance.mint
            else {
                return
            }

            let amount = tokenAmount(balance.uiTokenAmount)
            partialResult[mint, default: 0] += amount
        }
    }

    func tokenAmount(_ tokenAmount: SolanaTransactionHistoryDTO.TransactionDetails.Meta.TokenAmount?) -> Decimal {
        guard let tokenAmount else {
            return 0
        }

        if let uiAmountString = tokenAmount.uiAmountString, let value = Decimal(stringValue: uiAmountString) {
            return value
        }

        if let amountString = tokenAmount.amount,
           let amount = Decimal(stringValue: amountString) {
            let decimals = tokenAmount.decimals ?? 0
            return amount / pow(10, decimals)
        }

        return tokenAmount.uiAmount ?? 0
    }

    func fallbackCounterpartyAddress(
        accountKeys: [SolanaTransactionHistoryDTO.AccountKey],
        walletAddress: String
    ) -> String {
        accountKeys.first(where: { !$0.pubkey.caseInsensitiveEquals(to: walletAddress) })?.pubkey ?? walletAddress
    }
}
