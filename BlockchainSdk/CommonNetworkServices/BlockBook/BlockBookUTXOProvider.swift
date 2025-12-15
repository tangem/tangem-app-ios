//
//  BlockBookUTXOProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemNetworkUtils

/// Documentation: https://github.com/trezor/blockbook/blob/master/docs/api.md
class BlockBookUTXOProvider {
    static var rpcRequestId: Int = 0

    var host: String {
        "\(blockchain.currencySymbol.lowercased()).\(config.host)"
    }

    private let blockchain: Blockchain
    private let config: BlockBookConfig
    private let provider: TangemProvider<BlockBookTarget>

    var decimalValue: Decimal {
        blockchain.decimalValue
    }

    init(
        blockchain: Blockchain,
        blockBookConfig: BlockBookConfig,
        networkConfiguration: TangemProviderConfiguration
    ) {
        self.blockchain = blockchain
        config = blockBookConfig
        provider = TangemProvider<BlockBookTarget>(configuration: networkConfiguration)
    }

    func addressData(
        address: String,
        parameters: BlockBookTarget.AddressRequestParameters
    ) -> AnyPublisher<BlockBookAddressResponse, Error> {
        executeRequest(.address(address: address, parameters: parameters), responseType: BlockBookAddressResponse.self)
    }

    func rpcCall<Result: Decodable>(
        method: String,
        params: AnyEncodable,
        resultType: Result.Type
    ) -> AnyPublisher<JSONRPC.DefaultResponse<Result>, Error> {
        BlockBookUTXOProvider.rpcRequestId += 1
        let request = JSONRPC.Request(id: BlockBookUTXOProvider.rpcRequestId, method: method, params: params)
        return executeRequest(.rpc(request), responseType: JSONRPC.DefaultResponse<Result>.self)
    }

    func getFeeRatePerByte(for confirmationBlocks: Int) -> AnyPublisher<Decimal, Error> {
        rpcCall(
            method: "estimatesmartfee",
            params: AnyEncodable([confirmationBlocks]),
            resultType: BlockBookFeeRateResponse.Result.self
        )
        .withWeakCaptureOf(self)
        .tryMap { provider, response -> Decimal in
            try provider.convertFeeRate(response.result.get().feerate)
        }
        .eraseToAnyPublisher()
    }

    func convertFeeRate(_ fee: Decimal) throws -> Decimal {
        if fee <= 0 {
            throw BlockchainSdkError.failedToLoadFee
        }

        // estimatesmartfee returns fee in currency per kilobyte
        let bytesInKiloByte: Decimal = 1024
        let feeRatePerByte = fee * decimalValue / bytesInKiloByte

        return feeRatePerByte.rounded(roundingMode: .up)
    }
}

// MARK: - UTXONetworkProvider

extension BlockBookUTXOProvider: UTXONetworkProvider {
    /// https://docs.syscoin.org/docs/dev-resources/documentation/javascript-sdk-ref/blockbook/#get-utxo
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        executeRequest(.utxo(address: address), responseType: [BlockBookUnspentTxResponse].self)
            .withWeakCaptureOf(self)
            .map { $0.mapToUnspentOutput(outputs: $1) }
            .eraseToAnyPublisher()
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        executeRequest(.txDetails(txHash: hash), responseType: BlockBookAddressResponse.Transaction.self)
            .withWeakCaptureOf(self)
            .tryMap { try $0.mapToTransactionRecord(transaction: $1, address: address) }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        // Number of blocks we want the transaction to be confirmed in.
        // The lower the number the bigger the fee returned by 'estimatesmartfee'.
        return Publishers.Zip3(
            getFeeRatePerByte(for: 8),
            getFeeRatePerByte(for: 4),
            getFeeRatePerByte(for: 1)
        )
        .map { first, second, third -> UTXOFee in
            let fees = [first, second, third].sorted()
            return UTXOFee(
                slowSatoshiPerByte: fees[0],
                marketSatoshiPerByte: fees[1],
                prioritySatoshiPerByte: fees[2]
            )
        }
        .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        guard let transactionData = transaction.data(using: .utf8) else {
            return .anyFail(error: BlockchainSdkError.failedToSendTx)
        }

        return executeRequest(.sendBlockBook(tx: transactionData), responseType: JSONRPC.DefaultResponse<String>.self)
            .withWeakCaptureOf(self)
            .tryMap { provider, response in
                try TransactionSendResult(hash: response.result.get(), currentProviderHost: provider.host)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

extension BlockBookUTXOProvider {
    func executeRequest<T: Decodable>(_ request: BlockBookTarget.Request, responseType: T.Type) -> AnyPublisher<T, Error> {
        provider
            .requestPublisher(BlockBookTarget(request: request, config: config, blockchain: blockchain))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(responseType.self)
            .eraseError()
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

private extension BlockBookUTXOProvider {
    func mapToUnspentOutput(outputs: [BlockBookUnspentTxResponse]) -> [UnspentOutput] {
        outputs.compactMap { output in
            Decimal(stringValue: output.value).map { value in
                .init(blockId: output.height ?? 0, txId: output.txid, index: output.vout, amount: value.uint64Value)
            }
        }
    }

    func mapToTransactionRecord(transaction: BlockBookAddressResponse.Transaction, address: String) throws -> TransactionRecord {
        try BlockBookTransactionTransactionRecordMapper(blockchain: blockchain)
            .mapToTransactionRecord(transaction: transaction, address: address)
    }
}
