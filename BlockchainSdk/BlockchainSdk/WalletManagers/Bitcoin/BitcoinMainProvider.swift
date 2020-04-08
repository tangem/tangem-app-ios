//
//  BitcoinMainProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import RxSwift

class BitcoinMainProvider: BitcoinNetworkProvider {
    let blockchainInfoProvider = MoyaProvider<BlockchainInfoTarget>()
    let estimateFeeProvider = MoyaProvider<EstimateFeeTarget>()
    
    let address: String
    
    init(address: String) {
        self.address = address
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return addressData(address)
            .map {(addressResponse, unspentsResponse) throws -> BitcoinResponse in
                guard let balance = addressResponse.final_balance,
                    let txs = addressResponse.txs else {
                        throw "Fee request error"
                }
                
                let utxs: [BtcTx] = unspentsResponse.unspent_outputs?.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.tx_hash_big_endian,
                        let n = utxo.tx_output_n,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val)
                    return btx
                    } ?? []
                
                let satoshiBalance = Decimal(balance)/Decimal(100000000)
                let hasUnconfirmed = txs.first(where: {$0.block_height == nil}) != nil
                return BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs)
        }
    }
    
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return Publishers.Zip3(estimateFeeProvider.requestPublisher(.minimal),
                               estimateFeeProvider.requestPublisher(.normal),
                               estimateFeeProvider.requestPublisher(.priority))
            .tryMap { response throws -> BtcFee in
                guard let min = Decimal(String(data: response.0.data, encoding: .utf8)),
                    let normal = Decimal(String(data: response.1.data, encoding: .utf8)),
                    let priority = Decimal(String(data: response.2.data, encoding: .utf8)) else {
                        throw "Fee request error"
                }
                
                return BtcFee(minimalKb: min, normalKb: normal, priorityKb: priority)
        }
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return blockchainInfoProvider.requestPublisher(.send(txHex: transaction))
        .mapNotEmptyString()
        .eraseError()
        .eraseToAnyPublisher()
    }
    
    private func addressData(_ address: String) -> Single<(BlockchainInfoAddressResponse, BlockchainInfoUnspentResponse)> {
        return Single.zip(
            blockchainInfoProvider
                .rx
                .request(.address(address: address))
                .map(BlockchainInfoAddressResponse.self),
        
            blockchainInfoProvider
                .rx
                .request(.unspents(address: address))
                .map(BlockchainInfoUnspentResponse.self))
    }
}
