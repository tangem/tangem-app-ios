//
//  BlockchairNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import SwiftyJSON
import BitcoinCore
import TangemFoundation
import TangemNetworkUtils

class BlockchairNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool {
        switch endpoint {
        case .bitcoin:
            return true
        default:
            return false
        }
    }

    private let provider: NetworkProvider<BlockchairTarget>
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

    var host: String {
        let baseUrl = "https://api.blockchair.com/"
        let endpoint = endpoint.path
        let suffix = apiKey?.sha256() ?? "nil"
        return "\(baseUrl)_\(endpoint)_\(suffix)"
    }

    init(endpoint: BlockchairEndpoint, apiKey: String?, blockchain: Blockchain, configuration: NetworkProviderConfiguration) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        mapper = BlockchairTransactionRecordMapper(blockchain: blockchain)

        provider = NetworkProvider<BlockchairTarget>(configuration: configuration)
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        publisher(for: .address(address: address, limit: 1000, endpoint: endpoint, transactionDetails: true))
            .tryMap { [weak self] json -> (BitcoinResponse, [BlockchairTransactionShort]) in // [REDACTED_TODO_COMMENT]
                guard let self = self else { throw WalletError.empty }

                let addr = mapAddressBlock(address, json: json)
                let address = addr["address"]
                let balance = address["balance"].stringValue
                let script = address["script_hex"].stringValue

                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                guard let transactionsData = try? addr["transactions"].rawData(),
                      let transactions: [BlockchairTransactionShort] = try? jsonDecoder.decode([BlockchairTransactionShort].self, from: transactionsData) else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                guard let utxoData = try? addr["utxo"].rawData(),
                      let utxos: [BlockchairUtxo] = try? jsonDecoder.decode([BlockchairUtxo].self, from: utxoData) else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                // Unspents with blockId lower than or equal 1 is not currently available
                // This unspents related to transaction in Mempool and are pending. We should ignore this unspents
                let utxs: [BitcoinUnspentOutput] = utxos.compactMap { utxo -> BitcoinUnspentOutput? in
                    guard let hash = utxo.transactionHash,
                          let n = utxo.index,
                          let val = utxo.value,
                          let blockId = utxo.blockId,
                          blockId > 1
                    else {
                        return nil
                    }

                    let btx = BitcoinUnspentOutput(transactionHash: hash, outputIndex: n, amount: val, outputScript: script)
                    return btx
                }

                let pendingTxs = transactions.filter { $0.blockId <= 1 }
                let hasUnconfirmed = pendingTxs.count != 0

                let decimalBtcBalance = decimalSatoshiBalance / endpoint.blockchain.decimalValue
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, pendingTxRefs: [], unspentOutputs: utxs)

                return (bitcoinResponse, pendingTxs)
            }
            .flatMap { [weak self] (resp: (BitcoinResponse, [BlockchairTransactionShort])) -> AnyPublisher<BitcoinResponse, Error> in
                guard let self = self else { return .emptyFail }

                guard !resp.1.isEmpty else {
                    return .justWithError(output: resp.0)
                }

                let hashes = resp.1.map { $0.hash }
                return publisher(for: .txsDetails(hashes: hashes, endpoint: endpoint))
                    .tryMap { [weak self] json -> BitcoinResponse in
                        guard let self = self else { throw WalletError.empty }

                        let data = json["data"]
                        let txsData = hashes.map {
                            data[$0]
                        }

                        let txs = txsData.map {
                            self.getTransactionDetails(from: $0)
                        }

                        let oldResp = resp.0
                        var utxos = oldResp.unspentOutputs

                        let pendingBtcTxs: [PendingTransaction] = txs.compactMap {
                            guard let tx = $0 else { return nil }

                            let pendingTx = tx.toPendingTx(userAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)

                            // We must find unspent outputs if we encounter outgoing transaction,
                            // because Blockchair won't return this unspents in address request as utxos
                            if !pendingTx.isIncoming {
                                let unspents = tx.findUnspentOuputs(for: address)
                                unspents.forEach { utxos.appendIfNotContain($0) }
                            }

                            return pendingTx
                        }

                        //                        let basicTxs = pendingBtcTxs.map { $0.toBasicTx(userAddress: address) }

                        return BitcoinResponse(
                            balance: Decimal(utxos.reduce(0) { $0 + $1.amount }) / endpoint.blockchain.decimalValue,
                            hasUnconfirmed: oldResp.hasUnconfirmed,
                            pendingTxRefs: pendingBtcTxs,
                            unspentOutputs: utxos
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        publisher(for: .fee(endpoint: endpoint))
            .tryMap { json throws -> BitcoinFee in
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int else {
                    throw WalletError.failedToGetFee
                }

                let normal = Decimal(feePerByteSatoshi)
                let min = (Decimal(0.8) * normal).rounded(roundingMode: .down)
                let max = (Decimal(1.2) * normal).rounded(roundingMode: .down)

                let fee = BitcoinFee(
                    minimalSatoshiPerByte: min,
                    normalSatoshiPerByte: normal,
                    prioritySatoshiPerByte: max
                )
                return fee
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        publisher(for: .send(txHex: transaction, endpoint: endpoint))
            .tryMap { json throws -> String in
                let data = json["data"]

                guard let hash = data["transaction_hash"].string else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                return hash
            }
            .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<PendingTransaction, Error> {
        publisher(for: .txDetails(txHash: hash, endpoint: endpoint))
            .tryMap { [weak self] json -> PendingTransaction in
                guard let self = self else { throw WalletError.empty }

                let txJson = json["data"]["\(hash)"]

                guard let tx = getTransactionDetails(from: txJson) else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                return tx.toPendingTx(userAddress: address, decimalValue: endpoint.blockchain.decimalValue)
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    private func publisher(for type: BlockchairTarget.BlockchairTargetType) -> AnyPublisher<JSON, MoyaError> {
        provider
            .requestPublisher(BlockchairTarget(type: type, apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapJSON()
            .map { JSON($0) }
            .eraseToAnyPublisher()
    }

    private func execute<T: Decodable>(type: BlockchairTarget.BlockchairTargetType, response: T.Type) -> AnyPublisher<T, Error> {
        provider
            .requestPublisher(BlockchairTarget(type: type, apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(response.self, using: jsonDecoder)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    private func getTransactionDetails(from json: JSON) -> BlockchairTransactionDetailed? {
        guard let txData = try? json.rawData(),
              let tx = try? jsonDecoder.decode(BlockchairTransactionDetailed.self, from: txData)
        else { return nil }

        return tx
    }
}

// MARK: - UTXONetworkProvider

extension BlockchairNetworkProvider: UTXONetworkProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        // Check why if change only one of parameters, API responded as error
        execute(
            type: .address(address: address, limit: 1000, endpoint: endpoint, transactionDetails: true),
            response: BlockchairDTO.Address.Response.self
        )
        .withWeakCaptureOf(self)
        .tryMap { provider, response -> [UnspentOutput] in
            guard let addressResponse = response.data[address] else {
                throw WalletError.failedToParseNetworkResponse()
            }

            return provider.mapToUnspentOutputs(outputs: addressResponse.utxo)
        }
        .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        execute(type: .txDetails(txHash: hash, endpoint: endpoint), response: BlockchairDTO.TransactionInfo.Response.self)
            .withWeakCaptureOf(self)
            .tryMap { provider, response -> TransactionRecord in
                guard let transaction = response.data[hash] else {
                    throw WalletError.failedToParseNetworkResponse()
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
            .map { TransactionSendResult(hash: $0.data.transactionHash) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension BlockchairNetworkProvider {
    func mapToUnspentOutputs(outputs: [BlockchairDTO.Address.Response.AddressInfo.Utxo]) -> [UnspentOutput] {
        outputs.map {
            UnspentOutput(blockId: $0.blockId, hash: $0.transactionHash, index: $0.index, amount: $0.value)
        }
    }

    func mapToTransactionRecord(
        transaction: BlockchairDTO.TransactionInfo.Response.Transaction,
        address: String
    ) throws -> TransactionRecord {
        try mapper.mapToTransactionRecord(transaction: transaction, address: address)
    }
}

extension BlockchairNetworkProvider: BlockchairAddressBlockMapper {}
