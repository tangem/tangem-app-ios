//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import SwiftyJSON
import Combine
import RxSwift

enum StellarError: Error {
    case noFee
    case failedToBuildTransaction
    case requestFailed
}

class StellarWalletManager: WalletManager, BlockchainProcessable {
    typealias TTransactionBuilder = StellarTransactionBuilder
    typealias TNetworkManager = StellarNetworkManager
    typealias TWallet = CurrencyWallet
        
    var txBuilder: StellarTransactionBuilder!
    var network: StellarNetworkManager!
    var cardId: String!
    var wallet: Variable<CurrencyWallet>!
    var error = PublishSubject<Error>()
    var stellarSdk: StellarSDK!
    private var baseFee: Decimal?
    private var requestDisposable: Disposable?
    private var currencyWallet: CurrencyWallet { return wallet.value }
    
    func update() {
        let assetCode = currencyWallet.balances[.token]?.currencySymbol
        requestDisposable = network
            .getInfo(accountId: currencyWallet.address, assetCode: assetCode)
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.error.onNext(error)
            })
    }
    
    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let fullReserve = response.assetBalance == nil ? response.baseReserve * 2 : response.baseReserve * 3
        currencyWallet.balances[.coin]?.value = response.balance - fullReserve
        currencyWallet.balances[.token]?.value = response.assetBalance
        currencyWallet.balances[.reserve]?.value = fullReserve
        
        let currentDate = Date()
        for  index in currencyWallet.pendingTransactions.indices {
            if DateInterval(start: currencyWallet.pendingTransactions[index].date!, end: currentDate).duration > 10 {
                currencyWallet.pendingTransactions[index].status = .confirmed
            }
        }
    }
}

@available(iOS 13.0, *)
extension StellarWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        return txBuilder.buildForSign(transaction: transaction)
            .flatMap { [unowned self] buildForSignResponse in
                signer.sign(hashes: [buildForSignResponse.hash], cardId: self.cardId)
                    .map { return ($0, buildForSignResponse) }.eraseToAnyPublisher()
        }
        .tryMap {[unowned self] result throws in
            guard let tx = self.txBuilder.buildForSend(signature: result.0.signature, transaction: result.1.transaction) else {
                throw StellarError.failedToBuildTransaction
            }
            
            return tx
        }
        .flatMap {[unowned self] in self.network.send(transaction: $0)}
        .map {[unowned self] in
            self.currencyWallet.add(transaction: transaction)
            return $0
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension StellarWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        if let feeValue = self.baseFee {
            let feeAmount = Amount(with: currencyWallet.blockchain, address: source, value: feeValue)
            return Result.Publisher([feeAmount]).eraseToAnyPublisher()
        } else {
            return Fail(error: StellarError.noFee).eraseToAnyPublisher()
        }
    }
}
