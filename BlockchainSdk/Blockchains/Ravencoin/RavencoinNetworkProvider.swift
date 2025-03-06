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

// MARK: - BitcoinNetworkProvider

extension RavencoinNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.Zip(getWalletInfo(address: address), getUTXO(address: address))
            .flatMap { [weak self] wallet, outputs -> AnyPublisher<BitcoinResponse, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }

                let hasUnconfirmed = wallet.unconfirmedTxApperances != 0
                if hasUnconfirmed {
                    return getTransactions(request: .init(address: address))
                        .map { transactions -> BitcoinResponse in
                            self.mapToBitcoinResponse(
                                wallet: wallet,
                                outputs: outputs,
                                transactions: transactions
                            )
                        }
                        .eraseToAnyPublisher()
                }

                let response = mapToBitcoinResponse(wallet: wallet, outputs: outputs, transactions: [])
                return .justWithError(output: response)
            }
            .eraseToAnyPublisher()
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        getFeeRatePerByte(blocks: 10)
            .tryMap { [weak self] perByte in
                guard let self else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                // Increase rate just in case
                let perByte = perByte * 1.1
                let satoshi = perByte * decimalValue
                let minRate = satoshi
                let normalRate = satoshi * 12 / 10
                let priorityRate = satoshi * 15 / 10

                return BitcoinFee(
                    minimalSatoshiPerByte: minRate,
                    normalSatoshiPerByte: normalRate,
                    prioritySatoshiPerByte: priorityRate
                )
            }
            .eraseToAnyPublisher()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: RavencoinRawTransaction.Request(rawtx: transaction))
            .map { $0.txid }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mapping

// Incoming 0.88
// Outgoing 0.77

private extension RavencoinNetworkProvider {
    func mapToBitcoinResponse(
        wallet: RavencoinWalletInfo,
        outputs: [RavencoinWalletUTXO],
        transactions: [RavencoinTransactionInfo]
    ) -> BitcoinResponse {
        let unspentOutputs = outputs.map { utxo in
            BitcoinUnspentOutput(
                transactionHash: utxo.txid,
                outputIndex: utxo.vout,
                amount: utxo.satoshis,
                outputScript: utxo.scriptPubKey
            )
        }

        let pendingTxRefs = transactions
            .filter { $0.confirmations == 0 || $0.blockheight == -1 }
            .compactMap { transaction -> PendingTransaction? in
                mapToPendingTransaction(transaction: transaction, walletAddress: wallet.address)
            }

        return BitcoinResponse(
            balance: wallet.balance ?? 0,
            hasUnconfirmed: wallet.unconfirmedTxApperances != 0,
            pendingTxRefs: pendingTxRefs,
            unspentOutputs: unspentOutputs
        )
    }

    func mapToPendingTransaction(
        transaction: RavencoinTransactionInfo,
        walletAddress: String
    ) -> PendingTransaction? {
        let isIncoming = transaction.vin.allSatisfy { $0.addr != walletAddress }
        let hash = transaction.txid
        let timestamp = transaction.time * 1000
        let fee = transaction.fees
        let value: Decimal

        if isIncoming {
            // Find all outputs to the our address
            let outputs = transaction.vout.filter {
                $0.scriptPubKey.addresses.contains { $0 == walletAddress }
            }

            value = outputs.compactMap { Decimal(stringValue: $0.value) }.reduce(0, +)

        } else {
            // Find all outputs from the our address
            let outputs = transaction.vout.filter {
                $0.scriptPubKey.addresses.contains { $0 != walletAddress }
            }

            value = outputs.compactMap { Decimal(stringValue: $0.value) }.reduce(0, +)
        }

        let otherAddresses = transaction.vout.filter {
            $0.scriptPubKey.addresses.contains { $0 != walletAddress }
        }

        guard let otherAddress = otherAddresses.first?.scriptPubKey.addresses.first else {
            return nil
        }

        return PendingTransaction(
            hash: hash,
            destination: isIncoming ? walletAddress : otherAddress,
            value: value,
            source: isIncoming ? otherAddress : walletAddress,
            fee: fee,
            date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            isIncoming: isIncoming,
            transactionParams: nil
        )
    }
}

// MARK: - Private

private extension RavencoinNetworkProvider {
    func getWalletInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .wallet(address: address)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }

    func getTransactions(request: RavencoinTransactionHistory.Request) -> AnyPublisher<[RavencoinTransactionInfo], Error> {
        provider
            .requestPublisher(.init(host: host, target: .transactions(request: request)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinTransactionHistory.Response.self)
            .map { $0.txs }
            .eraseToAnyPublisher()
            .eraseError()
    }

    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.init(host: host, target: .utxo(address: address)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }

    func getFeeRatePerByte(blocks: Int) -> AnyPublisher<Decimal, Error> {
        provider
            .requestPublisher(.init(host: host, target: .fees(request: .init(nbBlocks: blocks))))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapJSON(failsOnEmptyData: true)
            .tryMap { json throws -> Decimal in
                guard let json = json as? [String: Any],
                      let rate = json["\(blocks)"] as? Double else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                let ratePerKilobyte = Decimal(floatLiteral: rate)
                return ratePerKilobyte / 1024
            }
            .eraseToAnyPublisher()
    }

    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .transaction(id: transactionId)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }

    func send(transaction: RavencoinRawTransaction.Request) -> AnyPublisher<RavencoinRawTransaction.Response, Error> {
        provider
            .requestPublisher(.init(host: host, target: .send(transaction: .init(rawtx: transaction.rawtx))))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RavencoinRawTransaction.Response.self)
            .eraseToAnyPublisher()
            .eraseError()
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
            UnspentOutput(blockId: $0.height ?? 0, hash: $0.txid, index: $0.vout, amount: $0.satoshis)
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
