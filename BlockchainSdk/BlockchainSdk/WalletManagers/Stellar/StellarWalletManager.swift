//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

enum StellarError: Error {
    case noFee
}

class StellarWalletManager: WalletManager {    
    var wallet: Wallet { return _wallet }

    private var _wallet: CurrencyWallet
    private let cardId: String
    private var baseFee: Decimal?
    //private let asset: Asset?
    private let stellarSdk: StellarSDK
    
    init(cardId: String, walletPublicKey: Data, walletConfig: WalletConfig, asset: Asset?, isTestnet: Bool) {
      
        let url = isTestnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
        self.stellarSdk = StellarSDK(withHorizonUrl: url)
        //self.asset = asset
        self.cardId = cardId
        let blockchain: Blockchain = isTestnet ? .stellarTestnet: .stellar
        let address = blockchain.makeAddress(from: walletPublicKey)
        self._wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        
        if let asset = asset {
            let assetAmount = Amount(type: .token, currencySymbol: asset.symbol, value: nil, address: asset.contractAddress, decimals: asset.decimals)
            _wallet.addAmount(assetAmount)
        }
    }
    
    func update() {
        
    }
}

extension StellarWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void) {
        
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

class StellarTransactionBuilder {
    
}
