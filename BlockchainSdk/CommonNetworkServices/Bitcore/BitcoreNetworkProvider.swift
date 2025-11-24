//
//  BitcoreNetworkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNetworkUtils

/// https://github.com/bitpay/bitcore/blob/master/packages/bitcore-node/docs/api-documentation.md
class BitcoreNetworkProvider {
    private let blockchain: Blockchain = .ducatus
    private let provider: TangemProvider<BitcoreTarget>

    init(configuration: TangemProviderConfiguration) {
        provider = TangemProvider<BitcoreTarget>(configuration: configuration)
    }
}

// MARK: - UTXONetworkProvider

extension BitcoreNetworkProvider: UTXONetworkProvider {
    var host: String {
        BitcoreTarget.balance(address: "").baseURL.hostOrUnknown
    }

    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        execute(target: .unspents(address: address), response: [BitcoreDTO.UTXO.Response].self)
            .withWeakCaptureOf(self)
            .map { $0.mapToUnspentOutputs(outputs: $1) }
            .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        Publishers.CombineLatest(
            execute(target: .tx(hash: hash), response: BitcoreDTO.TransactionInfo.Response.self),
            execute(target: .inputsOutputs(txHash: hash), response: BitcoreDTO.Coins.Response.self)
        )
        .withWeakCaptureOf(self)
        .tryMap { provider, response in
            try provider.mapToTransactionRecord(
                transaction: (transaction: response.0, inputs: response.1.inputs, outputs: response.1.outputs),
                address: address
            )
        }
        .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        let fee = UTXOFee(slowSatoshiPerByte: 89, marketSatoshiPerByte: 144, prioritySatoshiPerByte: 350)
        return .justWithError(output: fee)
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        execute(target: .send(txHex: transaction), response: BitcoreDTO.Send.Response.self)
            .withWeakCaptureOf(self)
            .map { provider, result in
                TransactionSendResult(hash: result.txid, currentProviderHost: provider.host)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension BitcoreNetworkProvider {
    func execute<T: Decodable>(target: BitcoreTarget, response: T.Type) -> AnyPublisher<T, Error> {
        provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(response.self)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

private extension BitcoreNetworkProvider {
    func mapToUnspentOutputs(outputs: [BitcoreDTO.UTXO.Response]) -> [UnspentOutput] {
        outputs.map {
            UnspentOutput(blockId: $0.mintHeight ?? 0, txId: $0.mintTxid, index: $0.mintIndex, amount: $0.value)
        }
    }

    func mapToTransactionRecord(transaction: BitcoreTransactionRecordMapper.Transaction, address: String) throws -> TransactionRecord {
        try BitcoreTransactionRecordMapper(blockchain: blockchain)
            .mapToTransactionRecord(transaction: transaction, address: address)
    }
}
