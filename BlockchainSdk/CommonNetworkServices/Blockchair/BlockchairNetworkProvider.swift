//
//  BlockchairNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemNetworkUtils

class BlockchairNetworkProvider {
    private let provider: TangemProvider<BlockchairTarget>
    private let endpoint: BlockchairEndpoint
    private let mapper: BlockchairTransactionRecordMapper
    private let apiKey: String?

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter(withFormat: "YYYY-MM-dd HH:mm:ss", locale: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()

    init(endpoint: BlockchairEndpoint, apiKey: String?, blockchain: Blockchain, configuration: TangemProviderConfiguration) {
        self.endpoint = endpoint
        self.apiKey = apiKey

        mapper = BlockchairTransactionRecordMapper(blockchain: blockchain)
        provider = TangemProvider<BlockchairTarget>(configuration: configuration)
    }
}

// MARK: - UTXONetworkProvider

extension BlockchairNetworkProvider: UTXONetworkProvider {
    var host: String {
        let baseUrl = "https://api.blockchair.com/"
        let endpoint = endpoint.path
        let suffix = apiKey?.sha256() ?? "nil"
        return "\(baseUrl)_\(endpoint)_\(suffix)"
    }

    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        // Check why if change only one of parameters, API responded as error
        execute(
            type: .address(address: address, limit: 1000, endpoint: endpoint, transactionDetails: true),
            response: BlockchairDTO.Address.Response.self
        )
        .withWeakCaptureOf(self)
        .tryMap { provider, response -> [UnspentOutput] in
            guard let addressResponse = response.data[address] else {
                throw BlockchainSdkError.failedToParseNetworkResponse()
            }

            return provider.mapToUnspentOutputs(outputs: addressResponse.utxo)
        }
        .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        execute(type: .txDetails(txHash: hash, endpoint: endpoint), response: BlockchairDTO.TransactionInfo.Response.self)
            .withWeakCaptureOf(self)
            .tryMap { provider, response -> TransactionRecord in
                // We have to find key ignore case type
                let transaction = response.data.first(where: { $0.key.caseInsensitiveEquals(to: hash) })?.value
                guard let transaction else {
                    throw BlockchainSdkError.failedToParseNetworkResponse()
                }

                return try provider.mapToTransactionRecord(transaction: transaction, address: address)
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        execute(type: .fee(endpoint: endpoint), response: BlockchairDTO.Fee.Response.self)
            .map { response in
                let feePerByteSatoshi = response.data.suggestedTransactionFeePerByteSat
                let normal = Decimal(feePerByteSatoshi)
                let min = (Decimal(0.8) * normal).rounded(roundingMode: .down)
                let max = (Decimal(1.2) * normal).rounded(roundingMode: .down)

                return UTXOFee(
                    slowSatoshiPerByte: min,
                    marketSatoshiPerByte: normal,
                    prioritySatoshiPerByte: max
                )
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        execute(type: .send(txHex: transaction, endpoint: endpoint), response: BlockchairDTO.Send.Response.self)
            .withWeakCaptureOf(self)
            .map { provider, response in
                TransactionSendResult(hash: response.data.transactionHash, currentProviderHost: provider.host)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension BlockchairNetworkProvider {
    func execute<T: Decodable>(type: BlockchairTarget.BlockchairTargetType, response: T.Type) -> AnyPublisher<T, Error> {
        provider
            .requestPublisher(BlockchairTarget(type: type, apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(response.self, using: jsonDecoder)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

private extension BlockchairNetworkProvider {
    func mapToUnspentOutputs(outputs: [BlockchairDTO.Address.Response.AddressInfo.Utxo]) -> [UnspentOutput] {
        outputs.map {
            UnspentOutput(blockId: $0.blockId, txId: $0.transactionHash, index: $0.index, amount: $0.value)
        }
    }

    func mapToTransactionRecord(
        transaction: BlockchairDTO.TransactionInfo.Response.Transaction,
        address: String
    ) throws -> TransactionRecord {
        try mapper.mapToTransactionRecord(transaction: transaction, address: address)
    }
}
