//
//  BinanceWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import RxSwift

class BinanceWalletManager: WalletManager<CurrencyWallet> {
    var txBuilder: BinanceTransactionBuilder!
    var network: BinanceNetworkManager!
    private var requestDisposable: Disposable?
    private var currencyWallet: CurrencyWallet { return wallet.value }
    private var latestTxDate: Date?
    
    override func update() {//check it
        requestDisposable = network
            .getInfo()
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.error.onNext(error)
            })
    }
    
    private func updateWallet(with response: BinanceInfoResponse) {
        currencyWallet.add(coinValue: Decimal(response.balance))
        txBuilder.binanceWallet.sequence = response.sequence
        txBuilder.binanceWallet.accountNumber = response.accountNumber
        
        let currentDate = Date()
        for  index in currencyWallet.pendingTransactions.indices {
            if DateInterval(start: currencyWallet.pendingTransactions[index].date!, end: currentDate).duration > 10 {
                currencyWallet.pendingTransactions[index].status = .confirmed
            }
        }
    }
}

@available(iOS 13.0, *)
extension BinanceWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        let msg = txBuilder.buildForSign(amount: transaction.amount.value, targetAddress: transaction.destinationAddress)
        let hash = msg.encodeForSignature()
        return signer.sign(hashes: [hash], cardId: cardId)
            .tryMap {[unowned self] response in
                guard let tx = self.txBuilder.buildForSend(signature: response.signature, hash: hash) else {
                    throw BitcoinError.failedToBuildTransaction
                }
                return tx
        }
        .flatMap {[unowned self] in
            self.network.send(transaction: $0).map {[unowned self] response in
                self.currencyWallet.add(transaction: transaction)
                self.latestTxDate = Date()
                return true
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
           return network.getFee()
               .tryMap { feeString throws -> [Amount] in
                   guard let feeValue = Decimal(feeString) else {
                       throw "Failed to get fee"
                   }
                   
                   return [Amount(with: self.currencyWallet.blockchain, address: source, value: feeValue)]
           }
            .eraseToAnyPublisher()
       }
}

extension BinanceWalletManager: ThenProcessable { }
