//
//  XRPWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import TangemSdk

class XRPWalletManager: WalletManager<CurrencyWallet> {
    var txBuilder: XRPTransactionBuilder!
    var network: XRPNetworkManager!
    var currencyWallet: CurrencyWallet { return wallet.value }    
    private var requestDisposable: Disposable?
    
    override func update() {//check it
        requestDisposable = network
            .getInfo(account: currencyWallet.address)
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.error.onNext(error)
            })
    }
    
    private func updateWallet(with response: XrpInfoResponse) {
        currencyWallet.add(coinValue: response.balance/Decimal(1000000))
        currencyWallet.add(reserveValue: (response.balance - response.reserve)/Decimal(1000000))

        txBuilder.account = currencyWallet.address
        txBuilder.sequence = response.sequence
        if response.balance != response.unconfirmedBalance {
            if currencyWallet.pendingTransactions.isEmpty {
                currencyWallet.addIncomingTransaction()
            }
        } else {
            currencyWallet.pendingTransactions = []
        }
    }
}

@available(iOS 13.0, *)
extension XRPWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        guard let walletReserve = currencyWallet.balances[.reserve]?.value,
            let hashToSign = txBuilder.buildForSign(transaction: transaction) else {
                return Fail(error: "Missing reserve").eraseToAnyPublisher()
        }
        
        return network
            .checkAccountCreated(account: transaction.sourceAddress)
            .tryMap{ isAccountCreated in
                if !isAccountCreated && transaction.amount.value < walletReserve {
                    throw "Target account is not created. Amount to send should be \(walletReserve) XRP + fee or more"
                }
        }
        .flatMap{[unowned self] in
            return signer.sign(hashes: [hashToSign], cardId: self.cardId)
        }
        .tryMap{[unowned self] response -> String in
            guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature) else {
                throw "Failed to build transaction"
            }
            
            return tx
        }
        .flatMap{[unowned self] builderResponse in
            self.network.send(blob: builderResponse)
                .map{[unowned self] response in
                    self.currencyWallet.add(transaction: transaction)
                    return true
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        return network.getFee()
            .map { xrpFeeResponse -> [Amount] in
                let min = xrpFeeResponse.min/Decimal(1000000)
                let normal = xrpFeeResponse.normal/Decimal(1000000)
                let max = xrpFeeResponse.max/Decimal(1000000)
                
                let minAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: min)
                let normalAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: normal)
                let maxAmount = Amount(with: self.currencyWallet.blockchain, address: self.currencyWallet.address, value: max)
                return [minAmount, normalAmount, maxAmount]
        }
        .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: ThenProcessable { }
