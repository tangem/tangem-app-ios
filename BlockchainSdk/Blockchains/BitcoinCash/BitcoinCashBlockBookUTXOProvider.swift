//
//  BitcoinCashNowNodesNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Combine

/// Adapter for existing BlockBookUTXOProvider
final class BitcoinCashBlockBookUTXOProvider {
    private let blockBookUTXOProvider: BlockBookUTXOProvider
    private let bitcoinCashAddressService: BitcoinCashAddressService

    init(blockBookUTXOProvider: BlockBookUTXOProvider, bitcoinCashAddressService: BitcoinCashAddressService) {
        self.blockBookUTXOProvider = blockBookUTXOProvider
        self.bitcoinCashAddressService = bitcoinCashAddressService
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
    var host: String {
        blockBookUTXOProvider.host
    }

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
                resultType: Decimal.self
            )
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                let result = try response.result.get()
                let feeRate = try provider.blockBookUTXOProvider.convertFeeRate(result)

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
                resultType: String.self
            )
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                try TransactionSendResult(hash: response.result.get(), currentProviderHost: provider.host)
            }
            .eraseToAnyPublisher()
    }
}
