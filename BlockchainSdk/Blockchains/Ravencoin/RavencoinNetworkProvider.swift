//
//  RavencoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemFoundation

/// Documentations:
/// https://github.com/RavenDevKit/insight-api
/// https://github.com/RavenProject/Ravencoin/blob/master/doc/REST-interface.md
class RavencoinNetworkProvider: HostProvider {
    let host: String
    let provider: NetworkProvider<RavencoinTarget>

    private let blockchain = Blockchain.ravencoin(testnet: false)
    private var decimalValue: Decimal { blockchain.decimalValue }

    init(host: String, provider: NetworkProvider<RavencoinTarget>) {
        self.host = host
        self.provider = provider
    }
}

// MARK: - UTXONetworkProvider

extension RavencoinNetworkProvider: UTXONetworkProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        execute(target: .utxo(address: address), response: [RavencoinDTO.UTXO.Response].self)
            .withWeakCaptureOf(self)
            .map { $0.mapToUnspentOutputs(outputs: $1) }
            .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        execute(target: .transaction(id: hash), response: RavencoinDTO.TransactionInfo.Response.self)
            .withWeakCaptureOf(self)
            .tryMap { try $0.mapToTransactionRecord(transaction: $1, address: address) }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        let blocks = 10
        return execute(target: .fees(request: .init(nbBlocks: blocks)), response: [String: Decimal].self)
            .tryMap { [weak self] json in
                guard let self, let ratePerKilobyte = json["\(blocks)"] else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                let perByte = ratePerKilobyte / Constants.perKbRate
                let satoshi = perByte * blockchain.decimalValue
                let minRate = satoshi
                let normalRate = satoshi * 12 / 10
                let priorityRate = satoshi * 15 / 10

                return UTXOFee(
                    slowSatoshiPerByte: minRate,
                    marketSatoshiPerByte: normalRate,
                    prioritySatoshiPerByte: priorityRate
                )
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        execute(target: .send(transaction: .init(rawtx: transaction)), response: RavencoinDTO.Send.Response.self)
            .map { TransactionSendResult(hash: $0.txid) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension RavencoinNetworkProvider {
    func execute<T: Decodable>(target: RavencoinTarget.Target, response: T.Type) -> AnyPublisher<T, Error> {
        provider
            .requestPublisher(RavencoinTarget(host: host, target: target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(response.self)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

private extension RavencoinNetworkProvider {
    func mapToUnspentOutputs(outputs: [RavencoinDTO.UTXO.Response]) -> [UnspentOutput] {
        outputs.map {
            UnspentOutput(blockId: $0.height ?? 0, hash: Data(hex: $0.txid), index: $0.vout, amount: $0.satoshis)
        }
    }

    func mapToTransactionRecord(transaction: RavencoinDTO.TransactionInfo.Response, address: String) throws -> TransactionRecord {
        try RavencoinTransactionRecordMapper(blockchain: blockchain)
            .mapToTransactionRecord(transaction: transaction, address: address)
    }
}

// MARK: - Constants

private extension RavencoinNetworkProvider {
    enum Constants {
        /// We use 1000, because Ravencoin insight-api node return fee for per 1000 bytes.
        static let perKbRate: Decimal = 1000
    }
}
