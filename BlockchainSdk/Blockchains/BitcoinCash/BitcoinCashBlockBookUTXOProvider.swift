//
//  BitcoinCashNowNodesNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine

/// Adapter for existing BlockBookUTXOProvider
final class BitcoinCashBlockBookUTXOProvider: BitcoinNetworkProvider {
    private let blockBookUTXOProvider: BlockBookUTXOProvider
    private let bitcoinCashAddressService: BitcoinCashAddressService

    init(blockBookUTXOProvider: BlockBookUTXOProvider, bitcoinCashAddressService: BitcoinCashAddressService) {
        self.blockBookUTXOProvider = blockBookUTXOProvider
        self.bitcoinCashAddressService = bitcoinCashAddressService
    }

    var host: String {
        blockBookUTXOProvider.host
    }

    var supportsTransactionPush: Bool {
        blockBookUTXOProvider.supportsTransactionPush
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        blockBookUTXOProvider.getInfo(address: addAddressPrefixIfNeeded(address))
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        blockBookUTXOProvider
            .rpcCall(
                method: "estimatefee",
                params: AnyEncodable([Int]()),
                responseType: NodeEstimateFeeResponse.self
            )
            .tryMap { [weak self] response in
                guard let self else {
                    throw WalletError.empty
                }

                return try blockBookUTXOProvider.convertFeeRate(response.result.get().result)
            }.map { fee in
                // fee for BCH is constant
                BitcoinFee(minimalSatoshiPerByte: fee, normalSatoshiPerByte: fee, prioritySatoshiPerByte: fee)
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUTXOProvider
            .rpcCall(
                method: "sendrawtransaction",
                params: AnyEncodable([transaction]),
                responseType: SendResponse.self
            )
            .tryMap { try $0.result.get().result }
            .eraseToAnyPublisher()
    }

    private func addAddressPrefixIfNeeded(_ address: String) -> String {
        if bitcoinCashAddressService.isLegacy(address) {
            return address
        } else {
            let prefix = "bitcoincash:"
            return address.hasPrefix(prefix) ? address : prefix + address
        }
    }
}

// MARK: - UTXONetworkProvider

extension BitcoinCashBlockBookUTXOProvider: UTXONetworkProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        blockBookUTXOProvider.getUnspentOutputs(address: addAddressPrefixIfNeeded(address))
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        blockBookUTXOProvider.getTransactionInfo(hash: hash, address: addAddressPrefixIfNeeded(address))
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        blockBookUTXOProvider
            .rpcCall(
                method: "estimatefee",
                params: AnyEncodable([Int]()),
                responseType: NodeEstimateFeeResponse.self
            )
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                let feeRate = try provider.blockBookUTXOProvider.convertFeeRate(response.result.get().result)

                // fee for BCH is constant
                return UTXOFee(slowSatoshiPerByte: feeRate, marketSatoshiPerByte: feeRate, prioritySatoshiPerByte: feeRate)
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        blockBookUTXOProvider
            .rpcCall(
                method: "sendrawtransaction",
                params: AnyEncodable([transaction]),
                responseType: SendResponse.self
            )
            .tryMap { try TransactionSendResult(hash: $0.result.get().result) }
            .eraseToAnyPublisher()
    }
}
