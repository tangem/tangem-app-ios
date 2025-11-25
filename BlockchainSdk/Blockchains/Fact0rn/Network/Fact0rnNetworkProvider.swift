//
//  Fact0rnNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class Fact0rnNetworkProvider {
    // MARK: - Private Properties

    private let provider: ElectrumWebSocketProvider
    private let blockchain: Blockchain = .fact0rn
    private let converter: ElectrumScriptHashConverter

    // MARK: - Init

    init(provider: ElectrumWebSocketProvider) {
        self.provider = provider
        converter = .init(lockingScriptBuilder: .fact0rn())
    }
}

// MARK: - UTXONetworkProvider

extension Fact0rnNetworkProvider: UTXONetworkProvider {
    var host: String { provider.host }

    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        Future.async {
            let scriptHash = try self.converter.prepareScriptHash(address: address)
            let outputs = try await self.provider.getUnspents(identifier: .scriptHash(scriptHash))
            return self.mapToUnspentOutputs(outputs: outputs)
        }
        .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        Future.async {
            let transaction = try await self.provider.getTransaction(hash: hash)
            // We have to load the previous tx for every input that get full info about input
            // Because the original input doesn't have address and amount
            let inputs = try await transaction.vin.asyncCompactMap { input in
                if let txid = input.txid, let vout = input.vout {
                    return try await self.provider.getTransaction(hash: txid).vout[vout]
                }
                return nil
            }

            return try self.mapToTransactionRecord(transaction: transaction, inputs: inputs, address: address)
        }
        .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        Future.async {
            async let minimalEstimateFee = self.provider.estimateFee(block: Constants.minimalFeeBlockAmount)
            async let normalEstimateFee = self.provider.estimateFee(block: Constants.normalFeeBlockAmount)
            async let priorityEstimateFee = self.provider.estimateFee(block: Constants.priorityFeeBlockAmount)

            let minimalSatoshiPerByte = try await minimalEstimateFee / Constants.perKbRate
            let normalSatoshiPerByte = try await normalEstimateFee / Constants.perKbRate
            let prioritySatoshiPerByte = try await priorityEstimateFee / Constants.perKbRate

            return UTXOFee(slowSatoshiPerByte: minimalSatoshiPerByte, marketSatoshiPerByte: normalSatoshiPerByte, prioritySatoshiPerByte: prioritySatoshiPerByte)
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        // A thorough check of the capture logic is required. Then check the logic operation.
        // [REDACTED_TODO_COMMENT]
        Future.async {
            let hash: String = try await self.provider.send(transactionHex: transaction)
            return TransactionSendResult(hash: hash, currentProviderHost: self.host)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension Fact0rnNetworkProvider {
    func mapToUnspentOutputs(outputs: [ElectrumDTO.Response.ListUnspent]) -> [UnspentOutput] {
        outputs.map {
            UnspentOutput(blockId: $0.height.intValue(), txId: $0.txHash, index: $0.txPos, amount: $0.value.uint64Value)
        }
    }

    func mapToTransactionRecord(
        transaction: ElectrumDTO.Response.Transaction,
        inputs: [ElectrumDTO.Response.Vout],
        address: String
    ) throws -> TransactionRecord {
        try ElectrumTransactionRecordMapper(blockchain: blockchain)
            .mapToTransactionRecord(transaction: (transaction: transaction, inputs: inputs), address: address)
    }
}

extension Fact0rnNetworkProvider {
    enum ProviderError: LocalizedError {
        case failedScriptHashForAddress
    }

    enum Constants {
        static let minimalFeeBlockAmount = 8
        static let normalFeeBlockAmount = 4
        static let priorityFeeBlockAmount = 1

        /// We use 1000, because Electrum node return fee for per 1000 bytes.
        static let perKbRate: Decimal = 1000
    }
}
