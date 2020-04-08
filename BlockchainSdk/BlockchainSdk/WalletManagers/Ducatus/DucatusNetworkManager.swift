//
//  DucatusNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import Moya

class DucatusNetworkManager: BitcoinNetworkProvider {
    let provider: BitcoreProvider
    
    init(address: String) {
        provider = BitcoreProvider(address: address)
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return Single.zip(provider.getBalance(), provider.getUnspents())
            .map { balance, unspents throws -> BitcoinResponse in
                guard let confirmed = balance.confirmed,
                    let unconfirmed = balance.unconfirmed else {
                        throw  "Failed to get request"
                }
                
                let utxs: [BtcTx] = unspents.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.mintTxid,
                        let n = utxo.mintIndex,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val))
                    return btx
                }
                
                let balance = Decimal(confirmed)/Decimal(100000000)
                return BitcoinResponse(balance: balance, hasUnconfirmed: confirmed != unconfirmed, txrefs: utxs)
        }
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.send(transaction)
            .tryMap { response throws -> String in
                if let id = response.txid {
                    return id
                } else {
                    throw "Empty response"
                }
        }.eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        let fee = BtcFee(minimalKb: 0.00091136,
                         normalKb: 0.00147456,
                         priorityKb: 0.003584)
        
        return Just(fee)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
