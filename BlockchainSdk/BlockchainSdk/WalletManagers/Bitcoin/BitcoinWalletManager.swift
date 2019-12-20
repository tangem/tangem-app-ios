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

enum BitcoinError: Error {
    case noUnspents
    case failedToBuildHash
    case failedToBuildTransaction
    case failedToMapNetworkResponse
}

class BitcoinWalletManager: WalletManager {
    var wallet: CurrentValueSubject<Wallet, Error>
    
    private let currencyWallet: CurrencyWallet
    private let txBuilder: BitcoinTransactionBuilder
    private let cardId: String
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, isTestnet: Bool) {
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .bitcoinTestnet : .bitcoin
        let address = blockchain.makeAddress(from: walletPublicKey)
        currencyWallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        self.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: isTestnet)
        wallet = CurrentValueSubject(currencyWallet)
    }
    
    func update() {
        //[REDACTED_TODO_COMMENT]
        txBuilder.unspentOutputs = []
    }
}

extension BitcoinWalletManager: TransactionBuilder {
    func getEstimateSize(for transaction: Transaction) -> Int? {
        guard let unspentOutputsCount = txBuilder.unspentOutputs?.count else {
            return nil
        }
        
        guard let tx = txBuilder.buildForSend(transaction: transaction, signature: Data(repeating: UInt8(0x01), count: 64 * unspentOutputsCount)) else {
            return nil
        }
        
        return tx.count + 1
    }
}

extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            completion(.failure(BitcoinError.failedToBuildHash))
            return
        }
        
        signer.sign(hashes: hashes, cardId: cardId) {[weak self] result in
            switch result {
            case .event(let response):
                guard let self = self else { return }
                
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature) else {
                    completion(.failure(BitcoinError.failedToBuildTransaction))
                    return
                }
                
                let txForSend = tx.toHexString()
                //[REDACTED_TODO_COMMENT]
            case .completion(let error):
                if let error = error {
                    completion(.failure(error))
                }
            }
        }
    }
}

extension BitcoinWalletManager: FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void) {
        //[REDACTED_TODO_COMMENT]
        completion(.success([]))
    }
}
