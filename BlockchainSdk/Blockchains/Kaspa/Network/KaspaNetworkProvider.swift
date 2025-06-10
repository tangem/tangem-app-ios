//
//  KaspaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemNetworkUtils

/// https://api.kaspa.org/docs#/
class KaspaNetworkProvider: HostProvider {
    var host: String {
        url.hostOrUnknown
    }

    private let url: URL
    private let isTestnet: Bool
    private let provider: TangemProvider<KaspaTarget>

    init(url: URL, isTestnet: Bool, networkConfiguration: TangemProviderConfiguration) {
        self.url = url
        self.isTestnet = isTestnet
        provider = TangemProvider<KaspaTarget>(configuration: networkConfiguration)
        provider.session.sessionConfiguration.timeoutIntervalForRequest = 30
    }

    func send(transaction: KaspaDTO.Send.Request) -> AnyPublisher<KaspaDTO.Send.Response, Error> {
        requestPublisher(for: .transactions(transaction: transaction))
    }

    func mass(data: KaspaDTO.Send.Request.Transaction) -> AnyPublisher<KaspaDTO.Mass.Response, Error> {
        requestPublisher(for: .mass(data: data))
    }

    func feeEstimate() -> AnyPublisher<KaspaDTO.EstimateFee.Response, Error> {
        requestPublisher(for: .feeEstimate)
    }
}

// MARK: - UTXONetworkAddressInfoProvider

extension KaspaNetworkProvider: UTXONetworkAddressInfoProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        requestPublisher(for: .utxos(address: address))
            .withWeakCaptureOf(self)
            .map { $0.mapToUnspentOutputs(outputs: $1) }
            .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        requestPublisher(for: .transaction(hash: hash, request: .init()))
            .withWeakCaptureOf(self)
            .tryMap { try $0.mapToTransactionRecord(transaction: $1, address: address) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension KaspaNetworkProvider {
    func requestPublisher<T: Decodable>(for request: KaspaTarget.Request) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return provider.requestPublisher(KaspaTarget(request: request, baseURL: url))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: decoder)
            .eraseError()
    }
}

// MARK: - Mapping

private extension KaspaNetworkProvider {
    func mapToUnspentOutputs(outputs: [KaspaDTO.UTXO.Response]) -> [UnspentOutput] {
        outputs.compactMap { output in
            Decimal(stringValue: output.utxoEntry.amount).map { amount in
                UnspentOutput(
                    blockId: output.utxoEntry.blockDaaScore.flatMap { Int($0) } ?? -1,
                    txId: output.outpoint.transactionId,
                    index: output.outpoint.index,
                    amount: amount.uint64Value
                )
            }
        }
    }

    func mapToTransactionRecord(
        transaction: KaspaDTO.TransactionInfo.Response,
        address: String
    ) throws -> TransactionRecord {
        try KaspaTransactionRecordMapper(isTestnet: isTestnet)
            .mapToTransactionRecord(transaction: transaction, address: address)
    }
}
