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
    var txBuilder: StellarTransactionBuilder!
    var network: StellarNetworkManager!
    var stellarSdk: StellarSDK!
    private var baseFee: Decimal?
    
    override func update(completion: @escaping (Result<Wallet, Error>)-> Void)  {
        requestDisposable = network
            .getInfo(accountId: wallet.address, assetCode: wallet.token?.currencySymbol)
            .subscribe(onSuccess: {[unowned self] response in
                self.updateWallet(with: response)
                completion(.success(self.wallet))
                }, onError: {error in
                    completion(.failure(error))
            })
    }
    
    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let fullReserve = wallet.token != nil ? response.baseReserve * 3 : response.baseReserve * 2
        wallet.add(reserveValue: fullReserve)
        wallet.add(coinValue: response.balance - fullReserve)
        if let assetBalance = response.assetBalance {
            wallet.add(tokenValue: assetBalance)
        }
        let currentDate = Date()
        for  index in wallet.transactions.indices {
            if DateInterval(start: wallet.transactions[index].date!, end: currentDate).duration > 10 {
                wallet.transactions[index].status = .confirmed
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
            self.wallet.add(transaction: transaction)
            return $0
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        if let feeValue = self.baseFee {
            let feeAmount = Amount(with: wallet.blockchain, address: source, value: feeValue)
            return Result.Publisher([feeAmount]).eraseToAnyPublisher()
        } else {
            return Fail(error: StellarError.noFee).eraseToAnyPublisher()
        }
    }
}

extension StellarWalletManager: ThenProcessable { }
