//
//  Blockcypher.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import RxSwift

class BlockcypherProvider: BitcoinNetworkProvider {    
    let provider = MoyaProvider<BlockcypherTarget>()
    let address: String
    let chain: BlockcypherChain
    let coin: BlockcypherCoin
    
    init(address: String, coin: BlockcypherCoin, chain: BlockcypherChain) {
        self.address = address
        self.coin = coin
        self.chain = chain
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return provider
            .rx
            .request(.address(address: address, coin: coin, chain: chain))
            .map {response throws -> BitcoinResponse in
                let addressResponse = try response.map(BlockcypherAddressResponse.self)
                
                guard let balance = addressResponse.balance,
                    let uncBalance = addressResponse.unconfirmed_balance
                    else {
                        throw BitcoinError.failedToMapNetworkResponse
                }
                
                let satoshiBalance = Decimal(balance)/Decimal(100000000)
                let txs: [BtcTx] = addressResponse.txrefs?.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.tx_hash,
                        let n = utxo.tx_output_n,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val))
                    return btx
                    } ?? []
                
                let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: balance != uncBalance, txrefs: txs)
                return btcResponse
        }
    }
    
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return provider.requestPublisher(.fee(coin: coin, chain: chain))
            .tryMap { response throws -> BtcFee in
                let feeResponse = try response.map(BlockcypherFeeResponse.self)
                
                guard let minKb = feeResponse.low_fee_per_kb,
                    let normalKb = feeResponse.medium_fee_per_kb,
                    let maxKb = feeResponse.high_fee_per_kb else {
                        throw "Can't load fee"
                }
                
                let minKbValue = Decimal(minKb)/Decimal(100000000)
                let normalKbValue = Decimal(normalKb)/Decimal(100000000)
                let maxKbValue = Decimal(maxKb)/Decimal(100000000)
                let fee = BtcFee(minimalKb: minKbValue, normalKb: normalKbValue, priorityKb: maxKbValue)
                return fee
        }
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.requestPublisher(.send(txHex: transaction, coin: coin, chain: chain, accessToken: self.randomToken))
            .mapNotEmptyString()
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    //[REDACTED_TODO_COMMENT]
    private var randomToken: String {
        let tokens: [String] = ["aa8184b0e0894b88a5688e01b3dc1e82",
                                "56c4ca23c6484c8f8864c32fde4def8d",
                                "66a8a37c5e9d4d2c9bb191acfe7f93aa"]
        
        let tokenIndex = Int.random(in: 0...2)
        return tokens[tokenIndex]
    }
}
