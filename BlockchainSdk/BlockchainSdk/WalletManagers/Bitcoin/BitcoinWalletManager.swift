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
import RxSwift

enum BitcoinError: Error {
    case noUnspents
    case failedToBuildHash
    case failedToBuildTransaction
    case failedToMapNetworkResponse
    case failedToCalculateTxSize
}

class BitcoinWalletManager: WalletManager, FeeProvider {
    var wallet: PublishSubject<Wallet> = .init()
    var loadingError = PublishSubject<Error>()
    private let currencyWallet: CurrencyWallet
    private let txBuilder: BitcoinTransactionBuilder
    private let network: BitcoinNetworkManager
    private let cardId: String
    private var requestDisposable: Disposable?
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, blockchain: Blockchain) {
        self.cardId = cardId
        let address = blockchain.makeAddress(from: walletPublicKey)
        currencyWallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        self.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: blockchain.isTestnet)
        wallet.onNext(currencyWallet)
        network = BitcoinNetworkManager(address: address, isTestNet: blockchain.isTestnet)
        //[REDACTED_TODO_COMMENT]
    }
    
    func update() {//check it
        requestDisposable = network
            .getInfo()
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.loadingError.onNext(error)
            })
    }
    
    @available(iOS 13.0, *)
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        return network.getFee()
            .tryMap {[unowned self] response throws -> [Amount] in
                let kb = Decimal(1024)
                let minPerByte = response.minimalKb/kb
                let normalPerByte = response.normalKb/kb
                let maxPerByte = response.priorityKb/kb
                
                guard let estimatedTxSize = self.getEstimateSize(for: Transaction(amount: amount, fee: nil, sourceAddress: source, destinationAddress: destination)) else {
                    throw BitcoinError.failedToCalculateTxSize
                }
                
                let minFee = (minPerByte * estimatedTxSize)
                let normalFee = (normalPerByte * estimatedTxSize)
                let maxFee = (maxPerByte * estimatedTxSize)
                return [
                    Amount(with: self.currencyWallet.blockchain, address: source, value: minFee),
                    Amount(with: self.currencyWallet.blockchain, address: source, value: normalFee),
                    Amount(with: self.currencyWallet.blockchain, address: source, value: maxFee)
                ]
        }
        .eraseToAnyPublisher()
    }
    
    //[REDACTED_TODO_COMMENT]
    private func updateWallet(with response: BitcoinResponse) {
        currencyWallet.balances[.coin]?.value = response.balance
        txBuilder.unspentOutputs = response.txrefs
        if response.hacUnconfirmed {
            if currencyWallet.pendingTransactions.isEmpty {
                currencyWallet.pendingTransactions.append(Transaction(amount: Amount(with: currencyWallet.blockchain, address: ""), fee: nil, sourceAddress: "unknown", destinationAddress: currencyWallet.address))
            }
        } else {
            currencyWallet.pendingTransactions = []
        }
        wallet.onNext(currencyWallet)
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionBuilder {
    func getEstimateSize(for transaction: Transaction) -> Decimal? {
        guard let unspentOutputsCount = txBuilder.unspentOutputs?.count else {
            return nil
        }
        
        guard let tx = txBuilder.buildForSend(transaction: transaction, signature: Data(repeating: UInt8(0x01), count: 64 * unspentOutputsCount)) else {
            return nil
        }
        
        return Decimal(tx.count + 1)
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: BitcoinError.failedToBuildHash).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: hashes, cardId: cardId)
            .tryMap {[unowned self] response in
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature) else {
                    throw BitcoinError.failedToBuildTransaction
                }
                return tx.toHexString()
        }
        .flatMap {[unowned self] in
            self.network.send(transaction: $0).map {[unowned self] response in
                self.currencyWallet.add(transaction: transaction)
                self.wallet.onNext(self.currencyWallet)
                return true
            }
        }
        .eraseToAnyPublisher()
    }
}
