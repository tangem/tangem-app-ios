//
//  RadiantWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

final class RadiantWalletManager: BaseManager {
    // MARK: - Private Properties

    private let transactionBuilder: RadiantTransactionBuilder
    private let unspentOutputManager: UnspentOutputManager
    private let networkService: UTXONetworkProvider

    // MARK: - Init

    init(
        wallet: Wallet,
        transactionBuilder: RadiantTransactionBuilder,
        unspentOutputManager: UnspentOutputManager,
        networkService: UTXONetworkProvider
    ) {
        self.transactionBuilder = transactionBuilder
        self.unspentOutputManager = unspentOutputManager
        self.networkService = networkService
        super.init(wallet: wallet)
    }

    // MARK: - Implementation

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getInfo(address: wallet.address)
            .withWeakCaptureOf(self)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { manager, response in
                manager.updateWallet(with: response)
            })
    }
}

// MARK: - Private Implementation

private extension RadiantWalletManager {
    func updateWallet(with response: UTXOResponse) {
        unspentOutputManager.update(outputs: response.outputs, for: wallet.defaultAddress)
        let balance = unspentOutputManager.balance(blockchain: wallet.blockchain)
        wallet.add(coinValue: balance)

        let pending = response.pending.map {
            PendingTransactionRecordMapper().mapToPendingTransactionRecord(
                record: $0,
                blockchain: wallet.blockchain,
                address: wallet.address
            )
        }

        wallet.updatePendingTransaction(pending)
    }

    func sendViaCompileTransaction(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return Result {
            try transactionBuilder.buildForSign(transaction: transaction)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { walletManager, hashesForSign in
            signer
                .sign(hashes: hashesForSign, walletPublicKey: walletManager.wallet.publicKey)
        }
        .withWeakCaptureOf(self)
        .tryMap { walletManager, signatures in
            try walletManager.transactionBuilder.buildForSend(transaction: transaction, signatures: signatures).hexString
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, rawTransactionHex in
            walletManager.networkService
                .send(transaction: rawTransactionHex)
                .mapSendError(tx: rawTransactionHex.lowercased())
        }
        .withWeakCaptureOf(self)
        .map { walletManager, result -> TransactionSendResult in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: result.hash)
            walletManager.wallet.addPendingTransaction(record)
            return result
        }
        .eraseSendError()
        .eraseToAnyPublisher()
    }

    func calculateFee(for estimatedFeePerKb: Decimal, for estimateSize: Int) -> Fee {
        let decimalValue = wallet.blockchain.decimalValue
        let perKbDecimalValue = (estimatedFeePerKb * decimalValue).rounded(blockchain: wallet.blockchain, roundingMode: .up)
        let decimalFeeValue = Decimal(estimateSize) / Constants.perKbRate * perKbDecimalValue
        let feeAmountValue = (decimalFeeValue / decimalValue).rounded(blockchain: wallet.blockchain, roundingMode: .up)
        let feeAmount = Amount(with: wallet.blockchain, value: feeAmountValue)

        return Fee(feeAmount)
    }
}

// MARK: - WalletManager

extension RadiantWalletManager: WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        true
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        sendViaCompileTransaction(transaction, signer: signer)
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService
            .getFee()
            .withWeakCaptureOf(self)
            .tryMap { walletManager, fee -> [Fee] in
                try [fee.slowSatoshiPerByte, fee.marketSatoshiPerByte, fee.prioritySatoshiPerByte].map { estimatedFeePerKb in
                    let estimatedFeePerByte = estimatedFeePerKb / Constants.perKbRate
                    let decimalValue = walletManager.wallet.blockchain.decimalValue
                    let perByte = estimatedFeePerByte * decimalValue
                    let fee = try walletManager.transactionBuilder.estimateFee(amount: amount, destination: destination, feeRate: perByte.intValue())
                    let value = Decimal(fee) / decimalValue
                    return Fee(.init(with: walletManager.wallet.blockchain, value: value))
                }
            }
            .eraseToAnyPublisher()
    }
}

extension RadiantWalletManager {
    enum Constants {
        /**
         - We use 1000, because Electrum node return fee for per 1000 bytes.
         */
        static let perKbRate: Decimal = 1000
    }
}
