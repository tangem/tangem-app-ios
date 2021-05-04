//
//  BlockchairNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import Alamofire
import SwiftyJSON

class BlockchairNetworkProvider: BitcoinNetworkProvider {
    let provider = MoyaProvider<BlockchairTarget>()
    
    private let endpoint: BlockchairEndpoint
    private let apiKey: String
    
    init(endpoint: BlockchairEndpoint, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }
    
	func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        publisher(for: .address(address: address, endpoint: endpoint, transactionDetails: true, apiKey: apiKey))
            .tryMap { [unowned self] json -> BitcoinResponse in //[REDACTED_TODO_COMMENT]
                let addr = self.mapAddressBlock(address, json: json)
                let address = addr["address"]
                let balance = address["balance"].stringValue
                let script = address["script_hex"].stringValue
                
                guard let decimalSatoshiBalance = Decimal(string: balance) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                guard let transactionsData = try? addr["transactions"].rawData(),
                    let transactions: [BlockchairTransaction] = try? JSONDecoder().decode([BlockchairTransaction].self, from: transactionsData) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                guard let utxoData = try? addr["utxo"].rawData(),
                    let utxos: [BlockchairUtxo] = try? JSONDecoder().decode([BlockchairUtxo].self, from: utxoData) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                let utxs: [BtcTx] = utxos.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.transaction_hash,
                        let n = utxo.index,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val, script: script)
                    return btx
                }
                
                let hasUnconfirmed = transactions.first(where: {$0.block_id == -1 || $0.block_id == 1 }) != nil
                
                
                let decimalBtcBalance = decimalSatoshiBalance / self.endpoint.blockchain.decimalValue
                let bitcoinResponse = BitcoinResponse(balance: decimalBtcBalance, hasUnconfirmed: hasUnconfirmed, txrefs: utxs)
                
                return bitcoinResponse
        }
        .eraseToAnyPublisher()
    }
    
    func findErc20Tokens(address: String) -> AnyPublisher<[BlockchairToken], Error> {
        publisher(for: .findErc20Tokens(address: address, apiKey: apiKey))
            .tryMap { json -> [BlockchairToken] in
                let addr = self.mapAddressBlock(address, json: json)
                let tokensObject = addr["layer_2"]["erc_20"]
                let tokensData = try tokensObject.rawData()
                let tokens = try JSONDecoder().decode([BlockchairToken].self, from: tokensData)
                return tokens
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
	
	private func publisher(for target: BlockchairTarget) -> AnyPublisher<JSON, MoyaError> {
		provider
			.requestPublisher(target)
			.filterSuccessfulStatusAndRedirectCodes()
			.mapSwiftyJSON()
	}
    
    private func mapAddressBlock(_ address: String, json: JSON) -> JSON {
        let data = json["data"]
        let dictionary = data.dictionaryValue
        if dictionary.keys.contains(address) {
            return data["\(address)"]
        }
        
        let lowercasedAddress = address.lowercased()
        if dictionary.keys.contains(lowercasedAddress) {
            return data["\(lowercasedAddress)"]
        }

        return json
    }
}
