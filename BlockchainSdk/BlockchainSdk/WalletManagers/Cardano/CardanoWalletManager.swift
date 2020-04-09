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
        
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        <#code#>
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        <#code#>
    }
}

@available(iOS 13.0, *)
extension CardanoWalletManager: TransactionSizeEstimator {
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
