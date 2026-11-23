//
//  LendingDepositPreparationSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

struct LendingDepositPreparationSender {
    let preparationCall: TransferPreparationCall
    let blockchain: Blockchain
    let isDemo: Bool
    let transactionCreator: TransactionCreator
    let transactionsSender: MultipleTransactionsSender
    let signer: TangemSigner
    let gasEstimator: LendingDepositGasEstimating
    let hasPendingTransactions: () async throws -> Bool
    let onSent: () -> Void
}

// MARK: - TransferPreparation

extension LendingDepositPreparationSender: TransferPreparation {
    func gas(mainCall: TransferPreparationCall) async -> TransferPreparationGas? {
        await gasEstimator.gas(preparation: preparationCall, deposit: mainCall)
    }

    func send(mainCall: BSDKTransaction, gas: TransferPreparationGas) async throws -> TransactionDispatcherResult {
        guard !isDemo else {
            throw TransactionDispatcherResult.Error.demoAlert
        }

        let parameters = try Self.feeParameters(of: mainCall, gas: gas)
        try await ensureNoPendingTransactions()

        let mapper = TransactionDispatcherResultMapper()
        let transactions: (preparation: BSDKTransaction, deposit: BSDKTransaction)

        do {
            transactions = try await makeTransactions(mainCall: mainCall, parameters: parameters, gas: gas)
        } catch {
            throw mapper.mapError(error.toUniversalError(), transaction: .transfer(mainCall))
        }

        let results: [TransactionSendResult]

        do {
            results = try await transactionsSender.send([transactions.preparation, transactions.deposit], signer: signer).async()
        } catch {
            onSent()
            throw mapper.mapError(error.toUniversalError(), transaction: .transfer(transactions.deposit))
        }

        onSent()

        guard let depositResult = results.last else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return mapper.mapResult(depositResult, blockchain: blockchain, signer: signer.latestSignerType, isToken: false)
    }
}

// MARK: - Private

private extension LendingDepositPreparationSender {
    static func feeParameters(of mainCall: BSDKTransaction, gas: TransferPreparationGas) throws -> any EthereumFeeParameters {
        guard let parameters = mainCall.fee.parameters as? any EthereumFeeParameters else {
            throw TransactionDispatcherResult.Error.feeNotFound
        }

        guard parameters.nonce == nil else {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: LendingTransactionError.customNonce.toUniversalError())
        }

        guard parameters.gasLimit >= BigUInt(gas.total) else {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(
                error: LendingTransactionError.gasLimitTooLow(required: gas.total).toUniversalError()
            )
        }

        return parameters
    }

    func ensureNoPendingTransactions() async throws {
        let hasPendingTransactions: Bool

        do {
            hasPendingTransactions = try await self.hasPendingTransactions()
        } catch {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: error.toUniversalError())
        }

        guard !hasPendingTransactions else {
            throw TransactionDispatcherResult.Error.loadTransactionInfo(error: LendingTransactionError.previousTransactionPending.toUniversalError())
        }
    }

    func makeTransactions(
        mainCall: BSDKTransaction,
        parameters: any EthereumFeeParameters,
        gas: TransferPreparationGas
    ) async throws -> (preparation: BSDKTransaction, deposit: BSDKTransaction) {
        let preparationGas = BigUInt(gas.preparation)

        let preparationTransaction = try await transactionCreator.createTransaction(
            amount: Amount(with: blockchain, type: .coin, value: 0),
            fee: fee(parameters.changingGasLimit(to: preparationGas)),
            destinationAddress: preparationCall.destination,
            contractAddress: preparationCall.destination,
            params: EthereumTransactionParams(data: preparationCall.data)
        )

        let depositTransaction = try await transactionCreator.createTransaction(
            amount: mainCall.amount,
            fee: fee(parameters.changingGasLimit(to: parameters.gasLimit - preparationGas)),
            destinationAddress: mainCall.destinationAddress,
            contractAddress: mainCall.contractAddress,
            params: mainCall.params
        )

        return (preparationTransaction, depositTransaction)
    }

    func fee(_ parameters: any EthereumFeeParameters) -> Fee {
        let value = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        return Fee(Amount(with: blockchain, type: .coin, value: value), parameters: parameters)
    }
}
