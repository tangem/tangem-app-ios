//
//  ElectrumUTXONetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class ElectrumUTXONetworkProvider {
    let blockchain: Blockchain
    let provider: ElectrumWebSocketProvider
    let converter: ElectrumScriptHashConverter
    let settings: Settings

    init(blockchain: Blockchain, provider: ElectrumWebSocketProvider, converter: ElectrumScriptHashConverter, settings: Settings) {
        self.blockchain = blockchain
        self.provider = provider
        self.converter = converter
        self.settings = settings
    }
}

// MARK: - UTXONetworkProvider

extension ElectrumUTXONetworkProvider: UTXONetworkProvider {
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
            let inputs = try await transaction.vin.asyncCompactMap { input -> ElectrumDTO.Response.Vout? in
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
            let sourceFee = try await self.provider.estimateFee(block: 10)
            let targetFee = max(sourceFee, self.settings.recommendedFeePer1000Bytes)

            let minimal = targetFee
            let normal = targetFee * self.settings.normalFeeMultiplier
            let priority = targetFee * self.settings.priorityFeeMultiplier

            return UTXOFee(slowSatoshiPerByte: minimal, marketSatoshiPerByte: normal, prioritySatoshiPerByte: priority)
        }
        .eraseToAnyPublisher()
    }

    // A thorough check of the capture logic is required. Then check the logic operation.
    // [REDACTED_TODO_COMMENT]
    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        Future.async {
            let hash: String = try await self.provider.send(transactionHex: transaction)
            return TransactionSendResult(hash: hash, currentProviderHost: self.host)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension ElectrumUTXONetworkProvider {
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

// MARK: - Constants

extension ElectrumUTXONetworkProvider {
    struct Settings {
        let recommendedFeePer1000Bytes: Decimal
        let normalFeeMultiplier: Decimal
        let priorityFeeMultiplier: Decimal
    }
}
