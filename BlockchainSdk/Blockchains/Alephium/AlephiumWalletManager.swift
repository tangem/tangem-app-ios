//
//  AlephiumWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import TangemSdk

class AlephiumWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }

    var allowsFeeSelection: Bool {
        false
    }

    // MARK: - Private Implementation

    private let networkService: AlephiumNetworkService
    private let transactionBuilder: AlephiumTransactionBuilder

    // MARK: - Init

    init(wallet: Wallet, networkService: AlephiumNetworkService, transactionBuilder: AlephiumTransactionBuilder) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    // MARK: - Manager Implementation

    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        let accountInfoPublisher = networkService
            .getAccountInfo(for: wallet.address)

        cancellable = accountInfoPublisher
            .withWeakCaptureOf(self)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { walletManager, accountInfo in
                walletManager.updateWallet(accountInfo: accountInfo)
            })
    }

    /*
     We calculate the fee on our own, but we need the gasPrice value. If we throw the Amount from the transaction values, the api will throw an error that is not enough for the coms if we output it completely. Therefore, the logic is this, we throw it, take the gasLimit, count the gasAmount and multiply. Described in the documentation for the blockchain is Notion
     */
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        guard let amountBigIntValue = BigUInt(decimal: ALPH.Constants.dustAmountValue * wallet.blockchain.decimalValue) else {
            return .anyFail(error: WalletError.failedToGetFee)
        }

        return networkService.getFee(
            from: transactionBuilder.walletPublicKey.hexString,
            destination: destination,
            amount: amountBigIntValue
        )
        .withWeakCaptureOf(self)
        .tryMap { manager, gasPrice in
            let gasAmount = try manager.calculateGasAmount()
            let feeDecimalValue = (gasPrice * Decimal(gasAmount)) / manager.wallet.blockchain.decimalValue

            let feeAmount = Amount(with: manager.wallet.blockchain, value: feeDecimalValue)
            let feeParams = AlephiumFeeParameters(gasPrice: gasPrice, gasAmount: gasAmount)

            let fee = Fee(feeAmount, parameters: feeParams)
            return [fee]
        }
        .eraseToAnyPublisher()
    }

    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Result { try transactionBuilder.buildForSign(transaction: transaction) }
            .publisher
            .mapError { SendTxError(error: $0) }
            .withWeakCaptureOf(self)
            .flatMap { manager, hashForSign -> AnyPublisher<TransactionSendResult, SendTxError> in
                return signer
                    .sign(hash: hashForSign, walletPublicKey: manager.wallet.publicKey)
                    .withWeakCaptureOf(self)
                    .tryMap { walletManager, signature -> (unsignedTx: Data, signature: Data) in
                        let hashForSend = try walletManager.transactionBuilder.buildForSend(transaction: transaction)
                        return (hashForSend, signature)
                    }
                    .withWeakCaptureOf(self)
                    .flatMap { walletManager, buildForSend in
                        let (unsignedTx, signature) = buildForSend

                        return walletManager.networkService
                            .submitTx(unsignedTx: unsignedTx.hexString, signature: signature.hexString)
                    }
                    .withWeakCaptureOf(self)
                    .map { walletManager, transactionHash in
                        let mapper = PendingTransactionRecordMapper()
                        let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionHash)
                        walletManager.wallet.addPendingTransaction(record)
                        return TransactionSendResult(hash: transactionHash)
                    }
                    .eraseSendError()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func updateWallet(accountInfo: AlephiumAccountInfo) {
        let balanceValue = accountInfo.utxo
            .filter { $0.isConfirmed }
            .map { $0.value }
            .reduce(0, +)

        let convertedBalance = balanceValue / wallet.blockchain.decimalValue

        wallet.add(coinValue: convertedBalance)
        transactionBuilder.update(utxo: accountInfo.utxo)

        updateRecentTransactions(utxo: accountInfo.utxo)
    }

    private func updateRecentTransactions(utxo: [AlephiumUTXO]) {
        let isEmptyUnconfirmed = utxo.filter { !$0.isConfirmed }.isEmpty

        if isEmptyUnconfirmed {
            wallet.clearPendingTransaction()
        }
    }

    private func calculateGasAmount() throws -> Int {
        let unspents = transactionBuilder.unspents

        guard !unspents.isEmpty else {
            throw WalletError.failedToGetFee
        }

        let inputGas = ALPH.Constants.inputBaseGas * unspents.count
        let outputGas = ALPH.Constants.outputBaseGas * 2
        let txGas = inputGas + outputGas + ALPH.Constants.baseGas + ALPH.Constants.p2pkUnlockGas
        let gasAmount = max(ALPH.Constants.minimalGas, txGas)

        return gasAmount
    }
}

// MARK: - DustRestrictable

extension AlephiumWalletManager: DustRestrictable {
    var dustValue: Amount {
        Amount(with: wallet.blockchain, type: .coin, value: ALPH.Constants.dustAmountValue)
    }
}
