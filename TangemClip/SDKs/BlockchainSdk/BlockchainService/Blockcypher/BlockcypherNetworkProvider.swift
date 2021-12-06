//
//  BlockcypherNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class BlockcypherNetworkProvider: BitcoinNetworkProvider {
    let provider = MoyaProvider<BlockcypherTarget> ()
    let endpoint: BlockcypherEndpoint
    
    private var token: String? = nil
    private let tokens: [String]
    
    init(endpoint: BlockcypherEndpoint, tokens: [String]) {
        self.endpoint = endpoint
        self.tokens = tokens
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap {[unowned self] in
                self.provider
                    .requestPublisher(BlockcypherTarget(endpoint: self.endpoint, token: self.token, targetType: .address(address: address, unspentsOnly: true, limit: nil)))
                    .filterSuccessfulStatusAndRedirectCodes()
            }
            .catch{[unowned self] error -> AnyPublisher<Response, MoyaError> in
                self.changeToken(error)
                return Fail(error: error).eraseToAnyPublisher()
            }
            .retry(1)
            .eraseToAnyPublisher()
            .map(BlockcypherAddressResponse.self)
            .tryMap {[unowned self] addressResponse -> BitcoinResponse in
                guard let balance = addressResponse.balance,
                      let uncBalance = addressResponse.unconfirmed_balance
                else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let satoshiBalance = Decimal(balance)/self.endpoint.blockchain.decimalValue
                let txs: [BtcTx] = addressResponse.txrefs?.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.tx_hash,
                          let n = utxo.tx_output_n,
                          let val = utxo.value,
                          let script = utxo.script else {
                        return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val), script: script)
                    return btx
                } ?? []
                
                let btcResponse = BitcoinResponse(balance: satoshiBalance, hasUnconfirmed:  uncBalance != 0, txrefs: txs)
                return btcResponse
            }
            .eraseToAnyPublisher()
    }
    
    private func publisher(for target: BlockcypherTarget) -> AnyPublisher<Response, MoyaError> {
        Just(())
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] in
                self.provider
                    .requestPublisher(target)
                    .filterSuccessfulStatusAndRedirectCodes()
            }
            .catch { [unowned self] error -> AnyPublisher<Response, MoyaError> in
                self.changeToken(error)
                return Fail(error: error).eraseToAnyPublisher()
            }
            .retry(1)
            .eraseToAnyPublisher()
    }
    
    private func getRandomToken() -> String? {
        guard !tokens.isEmpty else { return nil }
        
        let tokenIndex = Int.random(in: 0..<tokens.count)
        return tokens[tokenIndex]
    }
    
    private func changeToken(_ error: MoyaError) {
        if case let MoyaError.statusCode(response) = error, response.statusCode == 429 {
            token = getRandomToken()
        }
    }
}
