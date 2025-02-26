//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BitcoinCore
import TangemFoundation

class BitcoinWalletManager: BaseManager, WalletManager, DustRestrictable {
    var allowsFeeSelection: Bool { true }
    var txBuilder: BitcoinTransactionBuilder!
    var networkService: BitcoinNetworkProvider!

    /*
     The current default minimum relay fee is 1 sat/vbyte.
     https://learnmeabitcoin.com/technical/transaction/fee/#:~:text=The%20current%20default%20minimum%20relay,mined%20in%20to%20the%20blockchain.
     */
    var minimalFeePerByte: Decimal { 1 }
    var minimalFee: Decimal { 0.00001 }
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: minimalFee)
    }

    var loadedUnspents: [BitcoinUnspentOutput] = []

    var currentHost: String { networkService.host }
    var outputsCount: Int? { loadedUnspents.count }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getInfo(addresses: wallet.addresses.map { $0.value })
            .eraseToAnyPublisher()
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case .failure(let error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }

    func updateWallet(with response: [BitcoinResponse]) {
        let balance = response.reduce(into: 0) { $0 += $1.balance }
        let hasUnconfirmed = response.contains(where: { $0.hasUnconfirmed })
        let unspents = response.flatMap { $0.unspentOutputs }

        wallet.add(coinValue: balance)
        loadedUnspents = unspents
        txBuilder.unspentOutputs = unspents

        wallet.clearPendingTransaction()
        if hasUnconfirmed {
            response
                .flatMap { $0.pendingTxRefs }
                .forEach {
                    let mapper = PendingTransactionRecordMapper()
                    let transaction = mapper.mapToPendingTransactionRecord($0, blockchain: wallet.blockchain)
                    wallet.addPendingTransaction(transaction)
                }
        }
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .tryMap { [weak self] response throws -> [Fee] in
                guard let self = self else { throw WalletError.empty }

                return self.processFee(response, amount: amount, destination: destination)
            }
            .eraseToAnyPublisher()
    }

    private func send(_ transaction: Transaction, signer: TransactionSigner, sequence: Int) -> AnyPublisher<TransactionSendResult, SendTxError> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction, sequence: sequence) else {
            return .sendTxFail(error: SendTxError(error: WalletError.failedToBuildTx))
        }

        return signer.sign(
            hashes: hashes,
            walletPublicKey: wallet.publicKey
        )
        .tryMap { [weak self] signatures -> (String) in
            guard let self = self else { throw WalletError.empty }

            guard let tx = txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: sequence) else {
                throw WalletError.failedToBuildTx
            }

            return tx.hexString.lowercased()
        }
        .flatMap { [weak self] tx -> AnyPublisher<TransactionSendResult, Error> in
            guard let self else { return .emptyFail }

            return networkService.send(transaction: tx).tryMap { [weak self] hash in
                guard let self = self else { throw WalletError.empty }

                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hash)
            }
            .mapSendError(tx: tx)
            .eraseToAnyPublisher()
        }
        .eraseSendError()
        .eraseToAnyPublisher()
    }

    func processFee(_ response: BitcoinFee, amount: Amount, destination: String) -> [Fee] {
        // Don't remove `.rounded` from here, intValue can sometimes go crazy
        // e.g. with the Decimal of (662701 / 3), producing 0 integer
        var minRate = (max(response.minimalSatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .up) as NSDecimalNumber).intValue
        var normalRate = (max(response.normalSatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .up) as NSDecimalNumber).intValue
        var maxRate = (max(response.prioritySatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .up) as NSDecimalNumber).intValue

        var minFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minRate, senderPay: false, changeScript: nil, sequence: .max)
        var normalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: normalRate, senderPay: false, changeScript: nil, sequence: .max)
        var maxFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: maxRate, senderPay: false, changeScript: nil, sequence: .max)

        let minimalFeeRate = (((minimalFee * Decimal(minRate)) / minFee).rounded(scale: 0, roundingMode: .up) as NSDecimalNumber).intValue
        let minimalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minimalFeeRate, senderPay: false, changeScript: nil, sequence: .max)
        if minFee < minimalFee {
            minRate = minimalFeeRate
            minFee = minimalFee
        }

        if normalFee < minimalFee {
            normalRate = minimalFeeRate
            normalFee = minimalFee
        }

        if maxFee < minimalFee {
            maxRate = minimalFeeRate
            maxFee = minimalFee
        }

        return [
            Fee(Amount(with: wallet.blockchain, value: minFee), parameters: BitcoinFeeParameters(rate: minRate)),
            Fee(Amount(with: wallet.blockchain, value: normalFee), parameters: BitcoinFeeParameters(rate: normalRate)),
            Fee(Amount(with: wallet.blockchain, value: maxFee), parameters: BitcoinFeeParameters(rate: maxRate)),
        ]
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: BitcoinTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Amount, destination: String) -> Fee {
        let fee = txBuilder.bitcoinManager.fee(
            for: amount.value,
            address: destination,
            feeRate: satoshiPerByte,
            senderPay: false,
            changeScript: nil,
            sequence: .max
        )
        return Fee(Amount(with: wallet.blockchain, value: fee), parameters: BitcoinFeeParameters(rate: satoshiPerByte))
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        txBuilder.unspentOutputs = loadedUnspents
        return send(transaction, signer: signer, sequence: SequenceValues.default.rawValue)
    }
}

extension BitcoinWalletManager: ThenProcessable {}
