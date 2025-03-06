//
//  Fact0rnNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class Fact0rnNetworkProvider: BitcoinNetworkProvider {
    // MARK: - Properties

    var supportsTransactionPush: Bool { false }
    var host: String { provider.host }

    // MARK: - Private Properties

    private let provider: ElectrumWebSocketProvider
    private let blockchain: Blockchain = .fact0rn

    // MARK: - Init

    init(provider: ElectrumWebSocketProvider) {
        self.provider = provider
    }

    // MARK: - BitcoinNetworkProvider Implementation

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, any Error> {
        return Result { try Fact0rnAddressService.addressToScriptHash(address: address) }
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { provider, scriptHash in
                provider.getAddressInfo(identifier: .scriptHash(scriptHash))
            }
            .withWeakCaptureOf(self)
            .tryMap { provider, accountInfo in
                let outputScriptData = try Fact0rnAddressService.addressToScript(address: address).scriptData

                return try provider.mapBitcoinResponse(
                    account: accountInfo,
                    outputScript: outputScriptData.hexString
                )
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, any Error> {
        let minimalEstimateFeePublisher = estimateFee(confirmation: Constants.minimalFeeBlockAmount)
        let normalEstimateFeePublisher = estimateFee(confirmation: Constants.normalFeeBlockAmount)
        let priorityEstimateFeePublisher = estimateFee(confirmation: Constants.priorityFeeBlockAmount)

        return Publishers.Zip3(
            minimalEstimateFeePublisher,
            normalEstimateFeePublisher,
            priorityEstimateFeePublisher
        )
        .withWeakCaptureOf(self)
        .map { provider, values in
            let minimalSatoshiPerByte = values.0 / Constants.perKbRate
            let normalSatoshiPerByte = values.1 / Constants.perKbRate
            let prioritySatoshiPerByte = values.2 / Constants.perKbRate

            return (minimalSatoshiPerByte, normalSatoshiPerByte, prioritySatoshiPerByte)
        }
        .withWeakCaptureOf(self)
        .map { provider, values in
            return BitcoinFee(
                minimalSatoshiPerByte: values.0,
                normalSatoshiPerByte: values.1,
                prioritySatoshiPerByte: values.2
            )
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, any Error> {
        Future.async {
            return try await self.provider.send(transactionHex: transaction)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func getAddressInfo(identifier: ElectrumWebSocketProvider.Identifier) -> AnyPublisher<ElectrumAddressInfo, Error> {
        Future.async {
            async let balance = self.provider.getBalance(identifier: identifier)
            async let unspents = self.provider.getUnspents(identifier: identifier)

            return try await ElectrumAddressInfo(
                balance: Decimal(balance.confirmed) / self.blockchain.decimalValue,
                unconfirmed: Decimal(balance.unconfirmed) / self.blockchain.decimalValue,
                outputs: unspents.map { unspent in
                    ElectrumUTXO(
                        position: unspent.txPos,
                        hash: unspent.txHash,
                        value: unspent.value,
                        height: unspent.height
                    )
                }
            )
        }
        .eraseToAnyPublisher()
    }

    private func estimateFee(confirmation blocks: Int) -> AnyPublisher<Decimal, Error> {
        Future.async {
            try await self.provider.estimateFee(block: blocks)
        }
        .eraseToAnyPublisher()
    }

    private func send(transactionHex: String) -> AnyPublisher<String, Error> {
        Future.async {
            try await self.provider.send(transactionHex: transactionHex)
        }
        .eraseToAnyPublisher()
    }

    private func getTransactionInfo(hash: String) -> AnyPublisher<ElectrumDTO.Response.Transaction, Error> {
        Future.async {
            try await self.provider.getTransaction(hash: hash)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func mapBitcoinResponse(account: ElectrumAddressInfo, outputScript: String) throws -> BitcoinResponse {
        let hasUnconfirmed = account.unconfirmed != .zero
        let unspentOutputs = mapUnspent(outputs: account.outputs, outputScript: outputScript)

        return BitcoinResponse(
            balance: account.balance,
            hasUnconfirmed: hasUnconfirmed,
            pendingTxRefs: [],
            unspentOutputs: unspentOutputs
        )
    }

    private func mapUnspent(outputs: [ElectrumUTXO], outputScript: String) -> [BitcoinUnspentOutput] {
        outputs.map {
            BitcoinUnspentOutput(
                transactionHash: $0.hash,
                outputIndex: $0.position,
                amount: $0.value.uint64Value,
                outputScript: outputScript
            )
        }
    }
}

// MARK: - UTXONetworkProvider

extension Fact0rnNetworkProvider: UTXONetworkProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        Future.async {
            let scriptHash = try Fact0rnAddressService.addressToScriptHash(address: address)
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
        Future.async {
            let hash: String = try await self.provider.send(transactionHex: transaction)
            return TransactionSendResult(hash: hash)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension Fact0rnNetworkProvider {
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
