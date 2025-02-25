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
import BitcoinCore

class BlockcypherNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    var host: String {
        getTarget(for: .fee).baseURL.absoluteString
    }

    private let provider: NetworkProvider<BlockcypherTarget>
    private let endpoint: BlockcypherEndpoint
    private var token: String? = nil
    private let tokens: [String]

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return decoder
    }()

    init(endpoint: BlockcypherEndpoint, tokens: [String], configuration: NetworkProviderConfiguration) {
        self.endpoint = endpoint
        self.tokens = tokens
        provider = NetworkProvider<BlockcypherTarget>(configuration: configuration)
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        getFullInfo(address: address)
            .tryMap { [weak self] (addressResponse: BlockcypherFullAddressResponse<BlockcypherBitcoinTx>) -> BitcoinResponse in
                guard let self = self else { throw WalletError.empty }

                guard let balance = addressResponse.balance,
                      let uncBalance = addressResponse.unconfirmedBalance
                else {
                    throw WalletError.failedToParseNetworkResponse()
                }

                let satoshiBalance = balance / endpoint.blockchain.decimalValue

                var utxo: [BitcoinUnspentOutput] = []
                var pendingTxRefs: [PendingTransaction] = []

                addressResponse.txs?.forEach { tx in
                    if tx.blockIndex == -1 {
                        let pendingTx = tx.toPendingTx(userAddress: address, decimalValue: self.endpoint.blockchain.decimalValue)
                        pendingTxRefs.append(pendingTx)
                    } else {
                        guard let btcTx = tx.findUnspentOutput(for: address) else { return }

                        utxo.append(btcTx)
                    }
                }

                if uncBalance / endpoint.blockchain.decimalValue != pendingTxRefs.reduce(0, { $0 + $1.value }) {
                    BSDKLogger.error(error: "Unconfirmed balance and pending tx refs sum is not equal")
                }
                let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: !pendingTxRefs.isEmpty, pendingTxRefs: pendingTxRefs, unspentOutputs: utxo)
                return btcResponse
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        publisher(for: getTarget(for: .fee))
            .map(BlockcypherFeeResponse.self)
            .tryMap { feeResponse -> BitcoinFee in
                guard let minKb = feeResponse.low_fee_per_kb,
                      let normalKb = feeResponse.medium_fee_per_kb,
                      let maxKb = feeResponse.high_fee_per_kb else {
                    throw WalletError.failedToGetFee
                }

                let kb = Decimal(1024)
                let min = (Decimal(minKb) / kb).rounded(roundingMode: .up)
                let normal = (Decimal(normalKb) / kb).rounded(roundingMode: .up)
                let max = (Decimal(maxKb) / kb).rounded(roundingMode: .up)
                let fee = BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: normal, prioritySatoshiPerByte: max)
                return fee
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        publisher(for: getTarget(for: .send(txHex: transaction), withRandomToken: true))
            .map(BlockcypherSendResponse.self, using: jsonDecoder)
            .eraseError()
            .map { $0.tx.hash }
            .eraseToAnyPublisher()
    }

    func getTransaction(with hash: String) -> AnyPublisher<BitcoinTransaction, Error> {
        let endpoint = endpoint

        return publisher(for: getTarget(for: .txs(txHash: hash)))
            .map(BlockcypherTransaction.self)
            .eraseError()
            .tryMap { (tx: BlockcypherTransaction) -> BitcoinTransaction in
                guard
                    let hash = tx.hash,
                    let dateStr = tx.confirmed ?? tx.received,
                    let date = DateFormatter.iso8601withFractionalSeconds.date(from: dateStr)
                else {
                    throw BlockchainSdkError.failedToLoadTxDetails
                }

                let inputs = tx.inputs?.compactMap { $0.toBtcInput() } ?? []
                let outputs = tx.outputs?.compactMap { $0.toBtcOutput(decimals: endpoint.blockchain.decimalValue) } ?? []

                return BitcoinTransaction(hash: hash, isConfirmed: tx.block ?? 0 > 0, time: date, inputs: inputs, outputs: outputs)
            }
            .eraseToAnyPublisher()
    }

    private func getFullInfo<Tx: Codable>(address: String) -> AnyPublisher<BlockcypherFullAddressResponse<Tx>, MoyaError> {
        publisher(for: BlockcypherTarget(endpoint: endpoint, token: token, targetType: .address(address: address, unspentsOnly: true, limit: 1000, isFull: true)))
            .map(BlockcypherFullAddressResponse<Tx>.self, using: jsonDecoder)
    }

    private func getTarget(for type: BlockcypherTarget.BlockcypherTargetType, withRandomToken: Bool = false) -> BlockcypherTarget {
        .init(endpoint: endpoint, token: withRandomToken ? token ?? getRandomToken() : token, targetType: type)
    }

    private func publisher(for target: BlockcypherTarget) -> AnyPublisher<Response, MoyaError> {
        Just(())
            .setFailureType(to: Error.self)
            .flatMap { [weak self] _ -> AnyPublisher<Response, Error> in
                guard let self = self else {
                    return .emptyFail
                }

                return provider
                    .requestPublisher(target)
                    .filterSuccessfulStatusAndRedirectCodes()
                    .eraseError()
            }
            .catch { [weak self] error -> AnyPublisher<Response, Error> in
                guard let self = self else {
                    return .emptyFail
                }

                changeToken(error)
                return Fail(error: error).eraseToAnyPublisher()
            }
            .retry(1)
            .mapError { MoyaError.underlying($0, nil) }
            .eraseToAnyPublisher()
    }

    private func getRandomToken() -> String? {
        guard !tokens.isEmpty else { return nil }

        let tokenIndex = Int.random(in: 0 ..< tokens.count)
        return tokens[tokenIndex]
    }

    private func changeToken(_ error: Error) {
        if case MoyaError.statusCode(let response) = error, response.statusCode == 429 {
            token = getRandomToken()
        }
    }
}
