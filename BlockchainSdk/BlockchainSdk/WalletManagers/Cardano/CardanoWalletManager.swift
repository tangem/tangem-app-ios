//
//  CardanoWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import RxSwift
import Combine

enum CardanoError: Error {
    case noUnspents
    case failedToBuildHash
    case failedToBuildTransaction
    case failedToMapNetworkResponse
    case failedToCalculateTxSize
}

class CardanoWalletManager: WalletManager, BlockchainProcessable {
    typealias TWallet = CurrencyWallet
    typealias TNetworkManager = CardanoNetworkManager
    typealias TTransactionBuilder = CardanoTransactionBuilder
    
    var wallet: Variable<CurrencyWallet>!
    var error = PublishSubject<Error>()
    var txBuilder: CardanoTransactionBuilder!
    var network: CardanoNetworkManager!
    var cardId: String!
    var currencyWallet: CurrencyWallet { return wallet.value }
    
    private var requestDisposable: Disposable?
    
    func update() {//check it
        requestDisposable = network
            .getInfo(address: currencyWallet.address)
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.error.onNext(error)
            })
    }
    
    private func updateWallet(with response: (AdaliteBalanceResponse,[AdaliteUnspentOutput])) {
        currencyWallet.balances[.coin]?.value = response.0.balance
        txBuilder.unspentOutputs = response.1
        
        currencyWallet.pendingTransactions = currencyWallet.pendingTransactions.compactMap { pendingTx in
            if let pendingTxHash = pendingTx.hash {
                if response.0.transactionList.contains(pendingTxHash) {
                   return nil
                }
            }
            return pendingTx
        }
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        guard let walletAmount = currencyWallet.balances[.coin]?.value,
            let hashes = txBuilder.buildForSign(transaction: transaction, walletAmount: walletAmount) else {
            return Fail(error: CardanoError.failedToBuildHash).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: [hashes], cardId: cardId)
            .tryMap {[unowned self] response -> (tx: Data, hash: String) in
                guard let walletAmount = self.currencyWallet.balances[.coin]?.value, let tx = self.txBuilder.buildForSend(transaction: transaction, walletAmount: walletAmount, signature: response.signature) else {
                    throw CardanoError.failedToBuildTransaction
                }
                return tx
        }
        .flatMap {[unowned self] builderResponse in
            self.network.send(base64EncodedTx: builderResponse.tx.base64EncodedString()).map {[unowned self] response in
                var sendedTx = transaction
                sendedTx.hash = builderResponse.hash
                self.currencyWallet.add(transaction: sendedTx)
                return true
            }
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        guard let estimatedTxSize = self.getEstimateSize(for: Transaction(amount: amount, fee: nil, sourceAddress: source, destinationAddress: destination)) else {
            return Fail(error: CardanoError.failedToCalculateTxSize).eraseToAnyPublisher()
        }
        
        let a = Decimal(0.155381)
        let b = Decimal(0.000043946)
        
        let feeValue = a + b * estimatedTxSize
        let feeAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: feeValue)
        return Result.Publisher([feeAmount]).eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: TransactionSizeEstimator {
    func getEstimateSize(for transaction: Transaction) -> Decimal? {
        guard let walletAmount = currencyWallet.balances[.coin]?.value,
            let tx = txBuilder.buildForSend(transaction: transaction, walletAmount: walletAmount, signature: Data(repeating: UInt8(0x01), count: 64)) else {
            return nil
        }
        
        return Decimal(tx.tx.count)
    }
}
