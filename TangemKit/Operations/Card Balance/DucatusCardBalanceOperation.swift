//
//  DucatusCardBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

class DucatusCardBalanceOperation: BaseCardBalanceOperation {    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let provider = MoyaProvider<BitcoreTarget>(plugins: [NetworkLoggerPlugin(verbose: true)])
        let ducatusEngine = card.cardEngine as! DucatusEngine
        
        
        provider.request(.balance(address: ducatusEngine.walletAddress)) {[weak self] result in
            switch result {
            case .success(let response):
                guard let balanceResponse = try? response.map(BitcoreBalance.self) else {
                    self?.failOperationWith(error: "Json mapping error")
                    return
                }
                
                provider.request(.unspents(address: ducatusEngine.walletAddress)) {[weak self] result2 in
                    switch result2 {
                    case .success(let utxoMoyaResponse):
                        guard let utxoResponse = try? utxoMoyaResponse.map([BitcoreUtxo].self) else {
                            self?.failOperationWith(error: "Json mapping error")
                            return
                        }
                        
                        self?.handleBalanceLoaded(balance: balanceResponse, utxos: utxoResponse)
                    case .failure(let error):
                        self?.failOperationWith(error: error)
                    }
                }
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        }
    }
    
    func handleBalanceLoaded(balance: BitcoreBalance, utxos: [BitcoreUtxo]) {
        guard !isCancelled else {
            return
        }
        
        guard let confirmed = balance.confirmed,
            let unconfirmed = balance.unconfirmed else {
                failOperationWith(error: Localizations.loadedWalletErrorObtainingBlockchainData)
                return
        }
        
        let utxs: [BtcTx] = utxos.compactMap { utxo -> BtcTx?  in
            guard let hash = utxo.mintTxid,
                let n = utxo.mintIndex,
                let val = utxo.value else {
                    return nil
            }
            
            let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val))
            return btx
        }
        
        let ducatusEngine = card.cardEngine as! DucatusEngine
        let balance = Decimal(confirmed).satoshiToBtc
        card.walletValue = "\(balance.rounded(blockchain: .ducatus))"
        ducatusEngine.addressResponse = BtcResponse(balance: balance, unconfirmed_balance: Int(unconfirmed), txrefs: utxs)
        completeOperation()
    }
}
