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
    let txBuilder: BitcoinTransactionBuilder
    let unspentOutputManager: UnspentOutputManager
    let networkService: UTXONetworkProvider

    /*
     The current default minimum relay fee is 1 sat/vbyte.
     https://learnmeabitcoin.com/technical/transaction/fee/#:~:text=The%20current%20default%20minimum%20relay,mined%20in%20to%20the%20blockchain.
     */
    var minimalFeePerByte: Decimal { 1 }
    var minimalFee: Decimal { 0.00001 }
    var allowsFeeSelection: Bool { true }
    var dustValue: Amount {
        Amount(with: wallet.blockchain, value: minimalFee)
    }

    var currentHost: String { networkService.host }

    init(wallet: Wallet, txBuilder: BitcoinTransactionBuilder, unspentOutputManager: UnspentOutputManager, networkService: UTXONetworkProvider) {
        self.txBuilder = txBuilder
        self.unspentOutputManager = unspentOutputManager
        self.networkService = networkService

        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let publishers = wallet.addresses
            .compactMap { $0 as? LockingScriptAddress }
            .map { address in
                networkService.getInfo(address: address.value)
                    .map { UpdatingResponse(address: address, response: $0) }
            }

        cancellable = Publishers.MergeMany(publishers).collect()
            .receive(on: DispatchQueue.global())
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

    func updateWallet(with responses: [UpdatingResponse]) {
        responses.forEach { response in
            unspentOutputManager.update(outputs: response.response.outputs, for: response.address)
        }
        let balance = Decimal(unspentOutputManager.confirmedBalance()) / wallet.blockchain.decimalValue
        wallet.add(coinValue: balance)

        let mapper = PendingTransactionRecordMapper()
        let pending = responses.flatMap { response in
            response.response.pending.map {
                mapper.mapToPendingTransactionRecord(record: $0, blockchain: wallet.blockchain, address: response.address.value)
            }
        }

        wallet.updatePendingTransaction(pending)
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService.getFee()
            .withWeakCaptureOf(self)
            .tryMap { try $0.processFee($1, amount: amount, destination: destination) }
            .eraseToAnyPublisher()
    }

    func processFee(_ response: UTXOFee, amount: Amount, destination: String) throws -> [Fee] {
        // Don't remove `.rounded` from here, intValue can sometimes go crazy
        // e.g. with the Decimal of (662701 / 3), producing 0 integer
        var minRate = max(response.slowSatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
        var normalRate = max(response.marketSatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
        var maxRate = max(response.prioritySatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)

        var minFee = try txBuilder.fee(amount: amount.value, destination: destination, feeRate: minRate)
        var normalFee = try txBuilder.fee(amount: amount.value, destination: destination, feeRate: normalRate)
        var maxFee = try txBuilder.fee(amount: amount.value, destination: destination, feeRate: maxRate)

        let minimalFeeRate = ((minimalFee * Decimal(minRate)) / minFee).intValue(roundingMode: .up)
        let minimalFee = try txBuilder.fee(amount: amount.value, destination: destination, feeRate: minimalFeeRate)
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

// MARK: - BitcoinTransactionFeeCalculator

extension BitcoinWalletManager: BitcoinTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Decimal, destination: String) throws -> Fee {
        let fee = try txBuilder.fee(amount: amount, destination: destination, feeRate: satoshiPerByte)
        return Fee(Amount(with: wallet.blockchain, value: fee), parameters: BitcoinFeeParameters(rate: satoshiPerByte))
    }
}

// MARK: - TransactionSender

extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sequence: Int = SequenceValues.default.rawValue

        return Result { try txBuilder.buildForSign(transaction: transaction, sequence: sequence) }
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { manager, hashes in
                signer.sign(hashes: hashes, walletPublicKey: manager.wallet.publicKey)
            }
            .withWeakCaptureOf(self)
            .tryMap { manager, signatures -> String in
                let tx = try manager.txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: sequence)

                return tx.hexString.lowercased()
            }
            .withWeakCaptureOf(self)
            .flatMap { manager, transaction in
                manager.networkService
                    .send(transaction: transaction)
                    .mapSendError(tx: transaction)
            }
            .withWeakCaptureOf(self)
            .map { manager, result in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: result.hash)
                manager.wallet.addPendingTransaction(record)
                return result
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
}

extension BitcoinWalletManager {
    struct UpdatingResponse {
        let address: LockingScriptAddress
        let response: UTXOResponse
    }
}
