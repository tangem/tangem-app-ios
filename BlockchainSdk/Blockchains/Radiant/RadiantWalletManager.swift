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
        guard let address = wallet.defaultAddress as? LockingScriptAddress else {
            assertionFailure("Radiant have to use LockingScriptAddress as address")
            return
        }

        unspentOutputManager.update(outputs: response.outputs, for: address)
        let coinBalanceValue = Decimal(unspentOutputManager.confirmedBalance()) / wallet.blockchain.decimalValue
        wallet.add(coinValue: coinBalanceValue)

        let pending = response.pending.map {
            PendingTransactionRecordMapper().mapToPendingTransactionRecord(
                record: $0,
                blockchain: wallet.blockchain,
                address: address.value
            )
        }

        wallet.updatePendingTransaction(pending)
    }

    func sendViaCompileTransaction(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let hashesForSign: [Data]

        do {
            hashesForSign = try transactionBuilder.buildForSign(transaction: transaction)
        } catch {
            return .sendTxFail(error: error)
        }

        return signer
            .sign(hashes: hashesForSign, walletPublicKey: wallet.publicKey)
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
                let dummyTransactionFee: Fee = .init(
                    .init(with: walletManager.wallet.blockchain, value: fee.slowSatoshiPerByte)
                )

                let dummyTransaction = Transaction(
                    amount: amount,
                    fee: dummyTransactionFee,
                    sourceAddress: walletManager.wallet.address,
                    destinationAddress: destination,
                    changeAddress: walletManager.wallet.address
                )

                let estimatedSize = try walletManager.transactionBuilder.estimateTransactionSize(transaction: dummyTransaction)

                let minimalFee = walletManager.calculateFee(for: fee.slowSatoshiPerByte, for: estimatedSize)
                let normalFee = walletManager.calculateFee(for: fee.marketSatoshiPerByte, for: estimatedSize)
                let priorityFee = walletManager.calculateFee(for: fee.prioritySatoshiPerByte, for: estimatedSize)

                return [
                    minimalFee,
                    normalFee,
                    priorityFee,
                ]
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
