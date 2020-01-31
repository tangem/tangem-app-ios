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

class StellarWalletManager: WalletManager {    
    var wallet: PublishSubject<Wallet> = .init()
    var loadingError = PublishSubject<Error>()
    private var currencyWallet: CurrencyWallet
    private let cardId: String
    private var baseFee: Decimal?
    private let txBuilder: StellarTransactionBuilder
    private let network: StellarNetwotkManager
    private let stellarSdk: StellarSDK
    private var requestDisposable: Disposable?
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, token: Token?, blockchain: Blockchain) {
        
        let url = blockchain.isTestnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
        self.stellarSdk = StellarSDK(withHorizonUrl: url)
        self.cardId = cardId
        let address = blockchain.makeAddress(from: walletPublicKey)
        currencyWallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        currencyWallet.add(amount: Amount(with: blockchain, address: address, type: .reserve))
        if let token = token {
            currencyWallet.add(amount: Amount(with: token))
        }
        
        self.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: blockchain.isTestnet)
        self.network = StellarNetwotkManager(stellarSdk: stellarSdk)
        wallet.onNext(currencyWallet)
    }
    
    func update() {
        let assetCode = currencyWallet.balances[.token]?.currencySymbol
        requestDisposable = network
            .getInfo(accountId: currencyWallet.address, assetCode: assetCode)
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                }, onError: {[unowned self] error in
                    self.loadingError.onNext(error)
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
        wallet.onNext(currencyWallet)
    }
}

@available(iOS 13.0, *)
extension StellarWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        let cardId = self.cardId
        
        return txBuilder.buildForSign(transaction: transaction)
            .flatMap { buildForSignResponse in
                signer.sign(hashes: [buildForSignResponse.hash], cardId: cardId)
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
            self.wallet.onNext(self.currencyWallet)
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
