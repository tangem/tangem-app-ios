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

    override func updateWalletManager() async throws {
        do {
            let responses = try await networkService.getInfo(addresses: wallet.addresses).async()
            updateWallet(with: responses)
        } catch {
            wallet.clearAmounts()
            throw error
        }
    }

    func updateWallet(with responses: [UTXONetworkProviderUpdatingResponse]) {
        responses.forEach { response in
            unspentOutputManager.update(outputs: response.response.outputs, for: response.address)
        }
        let balance = unspentOutputManager.balance(blockchain: wallet.blockchain)
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
            .tryAsyncMap { try await $0.processFee($1, amount: amount, destination: destination) }
            .eraseToAnyPublisher()
    }

    func processFee(_ response: UTXOFee, amount: Amount, destination: String) async throws -> [Fee] {
        typealias FeeWithFeeRate = (_ fee: Int, _ rate: Int)

        async let minFee: FeeWithFeeRate = {
            let rate = max(response.slowSatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
            let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: rate)
            return (fee: fee, rate: rate)
        }()

        async let normalFee: FeeWithFeeRate = {
            let rate = max(response.marketSatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
            let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: rate)
            return (fee: fee, rate: rate)
        }()

        async let maxFee: FeeWithFeeRate = {
            let rate = max(response.prioritySatoshiPerByte, minimalFeePerByte).intValue(roundingMode: .up)
            let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: rate)
            return (fee: fee, rate: rate)
        }()

        let decimalValue = wallet.blockchain.decimalValue

        return try await [
            Fee(
                Amount(with: wallet.blockchain, value: Decimal(minFee.fee) / decimalValue),
                parameters: BitcoinFeeParameters(rate: minFee.rate)
            ),
            Fee(
                Amount(with: wallet.blockchain, value: Decimal(normalFee.fee) / decimalValue),
                parameters: BitcoinFeeParameters(rate: normalFee.rate)
            ),
            Fee(
                Amount(with: wallet.blockchain, value: Decimal(maxFee.fee) / decimalValue),
                parameters: BitcoinFeeParameters(rate: maxFee.rate)
            ),
        ]
    }
}

// MARK: - BitcoinTransactionFeeCalculator

extension BitcoinWalletManager: BitcoinTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Amount, destination: String) async throws -> Fee {
        let decimalValue = wallet.blockchain.decimalValue
        let fee = try await txBuilder.fee(amount: amount, address: destination, feeRate: satoshiPerByte)
        let amount = Amount(with: wallet.blockchain, value: Decimal(fee) / decimalValue)

        return Fee(amount, parameters: BitcoinFeeParameters(rate: satoshiPerByte))
    }
}

// MARK: - TransactionSender

extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Future.async {
            try await self.txBuilder.buildForSign(transaction: transaction)
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, hashes in
            signer
                .sign(hashes: hashes, walletPublicKey: manager.wallet.publicKey)
        }
        .withWeakCaptureOf(self)
        .tryAsyncMap { manager, signatures -> String in
            let tx = try await manager.txBuilder.buildForSend(transaction: transaction, signatures: signatures)
            return tx.hex()
        }
        .withWeakCaptureOf(self)
        .flatMap { manager, transaction in
            manager.networkService
                .send(transaction: transaction)
                .mapAndEraseSendTxError(tx: transaction, currentHost: manager.currentHost)
        }
        .withWeakCaptureOf(self)
        .map { manager, result in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: result.hash)
            manager.wallet.addPendingTransaction(record)
            return result
        }
        .mapSendTxError(currentHost: currentHost)
        .eraseToAnyPublisher()
    }
}
