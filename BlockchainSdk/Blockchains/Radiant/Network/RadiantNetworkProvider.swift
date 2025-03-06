//
//  RadiantNetworkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class RadiantNetworkProvider {
    let provider: ElectrumWebSocketProvider
    let blockchain: Blockchain

    init(provider: ElectrumWebSocketProvider, isTestnet: Bool) {
        self.provider = provider

        blockchain = .radiant(testnet: isTestnet)
    }
}

// MARK: - UTXONetworkProvider

extension RadiantNetworkProvider: UTXONetworkProvider {
    var host: String { provider.host }

    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        Future.async {
            let scriptHash = try RadiantAddressUtils().prepareScriptHash(address: address)
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
            let inputs = try await transaction.vin.asyncMap { input in
                try await self.provider.getTransaction(hash: input.txid).vout[input.vout]
            }

            return try self.mapToTransactionRecord(transaction: transaction, inputs: inputs, address: address)
        }
        .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        Future.async {
            let sourceFee = try await self.provider.estimateFee(block: 10)
            let targetFee = max(sourceFee, Constants.recommendedFeePer1000Bytes)

            let minimal = targetFee
            let normal = targetFee * Constants.normalFeeMultiplier
            let priority = targetFee * Constants.priorityFeeMultiplier

            return UTXOFee(slowSatoshiPerByte: minimal, marketSatoshiPerByte: normal, prioritySatoshiPerByte: priority)
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        Future.async {
            let hash: String = try await self.provider.send(transactionHex: transaction)
            return TransactionSendResult(hash: hash)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension RadiantNetworkProvider {
    func mapToUnspentOutputs(outputs: [ElectrumDTO.Response.ListUnspent]) -> [UnspentOutput] {
        outputs.map {
            UnspentOutput(blockId: $0.height.intValue(), hash: $0.txHash, index: $0.txPos, amount: $0.value.uint64Value)
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

// MARK: - Constants

extension RadiantNetworkProvider {
    enum Constants {
        /*
         This minimal rate fee for successful transaction from constant
         -  Relying on answers from blockchain developers and costs from the official application (Electron-Radiant).
         - 10000 satoshi per byte or 0.1 RXD per KB.
         */

        static let recommendedFeePer1000Bytes: Decimal = .init(stringValue: "0.1")!
        static let normalFeeMultiplier: Decimal = .init(stringValue: "1.5")!
        static let priorityFeeMultiplier: Decimal = .init(stringValue: "2")!
    }
}
