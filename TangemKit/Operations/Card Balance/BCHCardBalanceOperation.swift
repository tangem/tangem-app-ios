//
//  BCHCardBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

class BCHCardBalanceOperation: BaseCardBalanceOperation {
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let provider = MoyaProvider<BlockchairTarget>(plugins: [NetworkLoggerPlugin(verbose: true)])
        let bchEngine = card.cardEngine as! BCHEngine

        provider.request(.address(address: bchEngine.walletAddress)) {[weak self] result in
            switch result {
            case .success(let response):
                guard  let json = try? JSON(data: response.data) else {
                      self?.failOperationWith(error: "Json mapping error")
                    return
                }
                
                let data = json["data"]
                let addr = data["\(bchEngine.walletAddress)"]
                let address = addr["address"]
                let balance = address["balance"].stringValue
                
                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    self?.failOperationWith(error: "Balance mapping error")
                    return
                }
                
                guard let transactionsData = try? addr["transactions"].rawData(),
                    let transactions: [BlockchairTransaction] = try? JSONDecoder().decode([BlockchairTransaction].self, from: transactionsData) else {
                        self?.failOperationWith(error: "Transactions mapping error")
                        return
                }
                
                guard let utxoData = try? addr["utxo"].rawData(),
                    let utxos: [BlockchairUtxo] = try? JSONDecoder().decode([BlockchairUtxo].self, from: utxoData) else {
                        self?.failOperationWith(error: "Utxos mapping error")
                        return
                }
                                
                let utxs: [BtcTx] = utxos.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.transaction_hash,
                        let n = utxo.index,
                        let val = utxo.value else {
                            return nil
                    }

                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val)
                    return btx
                }
                
                let hasUnconfirmed = transactions.first(where: {$0.block_id == -1 || $0.block_id == 1 }) != nil
                let unconfirmedBalance = hasUnconfirmed ? 1 : 0
                
                
                let decimalBtcBalance = decimalSatoshiBalance/Decimal(100000000)
                bchEngine.addressResponse = BtcResponse(balance: decimalBtcBalance, unconfirmed_balance: unconfirmedBalance, txrefs: utxs)
                
                self?.handleBalanceLoaded(balanceValue: "\(decimalBtcBalance.rounded(blockchain: .bitcoinCash))")
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        }
    }

    func handleBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue

        completeOperation()
    }
}
