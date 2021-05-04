//
//  DucatusNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class DucatusNetworkService: BitcoinNetworkProvider {
    let provider =  BitcoreProvider()
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Publishers.Zip(provider.getBalance(address: address), provider.getUnspents(address: address))
            .tryMap { balance, unspents throws -> BitcoinResponse in
                guard let confirmed = balance.confirmed,
                    let unconfirmed = balance.unconfirmed else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                let utxs: [BtcTx] = unspents.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.mintTxid,
                        let n = utxo.mintIndex,
                        let val = utxo.value,
                        let script = utxo.script else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val), script: script)
                    return btx
                }
                
                let balance = Decimal(confirmed)/Blockchain.ducatus.decimalValue
                return BitcoinResponse(balance: balance, hasUnconfirmed: unconfirmed != 0 , txrefs: utxs)
        }
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.send(transaction)
            .tryMap { response throws -> String in
                if let id = response.txid {
                    return id
                } else {
                    throw WalletError.failedToParseNetworkResponse
                }
        }.eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        let fee = BtcFee(minimalSatoshiPerByte: 89,
                         normalSatoshiPerByte: 144,
                         prioritySatoshiPerByte: 350)
        
        return Just(fee)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		Fail(error: BlockchainSdkError.notImplemented)
			.eraseToAnyPublisher()
	}
}
