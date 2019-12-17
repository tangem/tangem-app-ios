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

enum StellarError: Error {
    case noFee
    case failedToBuildTransaction
}

class StellarWalletManager: WalletManager {    
    var wallet: Wallet { return _wallet }
    
    private var _wallet: CurrencyWallet
    private let cardId: String
    private var baseFee: Decimal?
    private let txBuilder: StellarTransactionBuilder
    private let network: StellarNetwotkManager
    private let stellarSdk: StellarSDK
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, asset: Token?, isTestnet: Bool) {
        
        let url = isTestnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
        self.stellarSdk = StellarSDK(withHorizonUrl: url)
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .stellarTestnet: .stellar
        let address = blockchain.makeAddress(from: walletPublicKey)
        self._wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        
        if let asset = asset {
            let assetAmount = Amount(type: .token, currencySymbol: asset.symbol, value: nil, address: asset.contractAddress, decimals: asset.decimals)
            _wallet.addAmount(assetAmount)
        }
        
        self.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: isTestnet)
        self.network = StellarNetwotkManager(stellarSdk: stellarSdk)
    }
    
    func update() {
        network.getInfo(accountId: wallet.address)
            .sink(receiveCompletion: { completion in
            
            }) { result in
                
        }
    }
}

extension StellarWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        let cardId = self.cardId
        
        let _ = txBuilder.buildForSign(transaction: transaction)
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
        }) { result in
            completion(.success(result))
        }
    }
}

extension StellarWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void) {
        if let fee = self.baseFee {
            let feeAmount = Amount(type: .coin, currencySymbol: wallet.blockchain.currencySymbol, value: fee, address: source, decimals: wallet.blockchain.decimalCount)
            completion(.success([feeAmount]))
        } else {
            completion(.failure(StellarError.noFee))
        }
    }
}

