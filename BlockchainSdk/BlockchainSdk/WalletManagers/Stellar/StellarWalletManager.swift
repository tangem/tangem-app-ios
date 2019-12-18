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

enum StellarError: Error {
    case noFee
    case failedToBuildTransaction
    case requestFailed
}

class StellarWalletManager: WalletManager {    
    var wallet: CurrentValueSubject<Wallet, Error>
    
    private var _wallet: CurrencyWallet
    private let cardId: String
    private var baseFee: Decimal?
    private let txBuilder: StellarTransactionBuilder
    private let network: StellarNetwotkManager
    private let stellarSdk: StellarSDK
    private var updateSubscription: AnyCancellable?
    private var sendSubscription: AnyCancellable?
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, token: Token?, isTestnet: Bool) {
        
        let url = isTestnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
        self.stellarSdk = StellarSDK(withHorizonUrl: url)
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .stellarTestnet: .stellar
        let address = blockchain.makeAddress(from: walletPublicKey)
        _wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        _wallet.add(amount: Amount(with: blockchain, address: address, type: .reserve))
        if let token = token {
            _wallet.add(amount: Amount(with: token))
        }
        
        self.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: isTestnet)
        self.network = StellarNetwotkManager(stellarSdk: stellarSdk)
        wallet = CurrentValueSubject(_wallet)
    }
    
    func update() {
        let assetCode = _wallet.balances[.token]?.currencySymbol
        updateSubscription = network.getInfo(accountId: wallet.value.address, assetCode: assetCode)
            .sink(receiveCompletion: {[unowned self] completion in
                if case let .failure(error) = completion {
                    self.wallet.send(completion: .failure(error))
                }
            }) { [unowned self] stellarResponse in
                self.updateWallet(with: stellarResponse)
        }
    }
    
    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let fullReserve = response.assetBalance == nil ? response.baseReserve * 2 : response.baseReserve * 3
        _wallet.balances[.coin]?.value = response.balance - fullReserve
        _wallet.balances[.token]?.value = response.assetBalance
        _wallet.balances[.reserve]?.value = fullReserve
        
        let currentDate = Date()
        for  index in _wallet.pendingTransactions.indices {
            if DateInterval(start: _wallet.pendingTransactions[index].date!, end: currentDate).duration > 10 {
                _wallet.pendingTransactions[index].status = .confirmed
            }
        }
        wallet.send(_wallet)
    }
}

extension StellarWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        let cardId = self.cardId
        
        sendSubscription = txBuilder.buildForSign(transaction: transaction)
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
        .sink(receiveCompletion: { completionResult in
            switch completionResult {
            case .finished:
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }) {[unowned self] result in
            self._wallet.add(transaction: transaction)
            self.wallet.send(self._wallet)
            completion(.success(result))
        }
    }
}

extension StellarWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void) {
        if let feeValue = self.baseFee {
            let feeAmount = Amount(with: _wallet.blockchain, address: source, value: feeValue)
            completion(.success([feeAmount]))
        } else {
            completion(.failure(StellarError.noFee))
        }
    }
}

