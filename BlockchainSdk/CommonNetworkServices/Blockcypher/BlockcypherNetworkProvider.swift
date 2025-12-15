//
//  BlockcypherNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemNetworkUtils

/// https://www.blockcypher.com/dev/bitcoin/#blockchain-api
class BlockcypherNetworkProvider {
    var host: String {
        BlockcypherTarget(endpoint: endpoint, token: token, targetType: .fee).baseURL.absoluteString
    }

    private let provider: TangemProvider<BlockcypherTarget>
    private let endpoint: BlockcypherEndpoint
    private let mapper: BlockcypherTransactionRecordMapper
    private var token: String?
    private let tokens: [String]

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(endpoint: BlockcypherEndpoint, tokens: [String], blockchain: Blockchain, configuration: TangemProviderConfiguration) {
        self.endpoint = endpoint
        self.tokens = tokens

        mapper = BlockcypherTransactionRecordMapper(blockchain: blockchain)
        provider = TangemProvider<BlockcypherTarget>(configuration: configuration)
    }
}

// MARK: - UTXONetworkProvider

extension BlockcypherNetworkProvider: UTXONetworkProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        execute(
            type: .address(address: address, unspentsOnly: true, limit: 1000, isFull: false),
            isRandomToken: false,
            response: BlockcypherDTO.Address.Response.self
        )
        .withWeakCaptureOf(self)
        .map { $0.mapToUnspentOutputs(response: $1) }
        .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        execute(
            type: .txs(txHash: hash),
            isRandomToken: false,
            response: BlockcypherDTO.TransactionInfo.Response.self
        )
        .withWeakCaptureOf(self)
        .tryMap { try $0.mapToTransactionRecord(transaction: $1, address: address) }
        .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        execute(
            type: .fee,
            isRandomToken: false,
            response: BlockcypherDTO.Fee.Response.self
        )
        .map { response in
            let kb = Decimal(1024)
            let min = (Decimal(response.lowFeePerKb) / kb).rounded(roundingMode: .up)
            let normal = (Decimal(response.mediumFeePerKb) / kb).rounded(roundingMode: .up)
            let max = (Decimal(response.highFeePerKb) / kb).rounded(roundingMode: .up)
            return UTXOFee(slowSatoshiPerByte: min, marketSatoshiPerByte: normal, prioritySatoshiPerByte: max)
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        execute(
            type: .send(txHex: transaction),
            isRandomToken: true,
            response: BlockcypherDTO.Send.Response.self
        )
        .withWeakCaptureOf(self)
        .map { provider, result in
            TransactionSendResult(hash: result.tx.hash, currentProviderHost: provider.host)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension BlockcypherNetworkProvider {
    func execute<T: Decodable>(type: BlockcypherTarget.BlockcypherTargetType, isRandomToken: Bool, response: T.Type) -> AnyPublisher<T, Error> {
        let token: String? = isRandomToken ? (token ?? tokens.randomElement()) : token
        let target = BlockcypherTarget(endpoint: endpoint, token: token, targetType: type)
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self, using: jsonDecoder)
            .mapError { [weak self] error in
                self?.changeTokenIfNeeded(error)
                return error as Error
            }
            .retry(1)
            .eraseToAnyPublisher()
    }

    func changeTokenIfNeeded(_ error: MoyaError) {
        switch error {
        case .statusCode(let response) where response.statusCode == 429:
            token = tokens.randomElement()
        default:
            break
        }
    }
}

// MARK: - Mapping

private extension BlockcypherNetworkProvider {
    func mapToUnspentOutputs(response: BlockcypherDTO.Address.Response) -> [UnspentOutput] {
        let outputs = [response.unconfirmedTxrefs, response.txrefs].compactMap { $0 }.flatMap { $0 }
        return outputs.map {
            // From docs:
            // Height of the block that contains this transaction input/output. If it's unconfirmed, this will equal -1.
            UnspentOutput(blockId: $0.blockHeight ?? -1, txId: $0.txHash, index: $0.txOutputN, amount: $0.value)
        }
    }

    func mapToTransactionRecord(
        transaction: BlockcypherDTO.TransactionInfo.Response,
        address: String
    ) throws -> TransactionRecord {
        try mapper.mapToTransactionRecord(transaction: transaction, address: address)
    }
}
