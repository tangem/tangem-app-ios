//
//  BlockchairProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import RxSwift
import Alamofire
import SwiftyJSON

class BlockchairProvider {
    let provider = MoyaProvider<BlockchairTarget>()
    
    let address: String
    let endpoint: BlockchairEndpoint
    
    init(address: String, endpoint: BlockchairEndpoint) {
        self.address = address
        self.endpoint = endpoint
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return provider
            .rx
            .request(.address(address: address, endpoint: endpoint))
            .map { [unowned self] response throws -> BitcoinResponse in
                guard let json = try? JSON(data: response.data) else {
                    throw "Json mapping error"
                }
                
                let data = json["data"]
                let addr = data["\(self.address)"]
                let address = addr["address"]
                let balance = address["balance"].stringValue
                
                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    throw "Balance mapping error"
                }
                
                guard let transactionsData = try? addr["transactions"].rawData(),
                    let transactions: [BlockchairTransaction] = try? JSONDecoder().decode([BlockchairTransaction].self, from: transactionsData) else {
                        throw "Transactions mapping error"
                }
                
                guard let utxoData = try? addr["utxo"].rawData(),
                    let utxos: [BlockchairUtxo] = try? JSONDecoder().decode([BlockchairUtxo].self, from: utxoData) else {
                        throw "Utxos mapping error"
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
                
                
                let decimalBtcBalance = decimalSatoshiBalance/Decimal(100000000)
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs)
                
                return bitcoinResponse
        }
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return provider.requestPublisher(.fee(endpoint: endpoint))
            .tryMap { response throws -> BtcFee in
                guard let json = try? JSON(data: response.data) else {
                    throw "Can't load fee"
                }
                
                let data = json["data"]
                guard let feePerByteSatoshi = data["suggested_transaction_fee_per_byte_sat"].int  else {
                    throw "Can't load fee"
                }
                
                let feeKbValue = Decimal(1024) * Decimal(feePerByteSatoshi) / Decimal(100000000)
                let fee = BtcFee(minimalKb: feeKbValue, normalKb: feeKbValue, priorityKb: feeKbValue)
                return fee
        }
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.requestPublisher(.send(txHex: transaction, endpoint: endpoint))
            .tryMap { response throws -> String in
                guard let json = try? JSON(data: response.data) else {
                    throw "Map response failed"
                }
                
                let data = json["data"]
                
                guard let hash = data["transaction_hash"].string else {
                   throw "Empty response"
                }
                
               return hash
        }
        .eraseToAnyPublisher()
    }
}
