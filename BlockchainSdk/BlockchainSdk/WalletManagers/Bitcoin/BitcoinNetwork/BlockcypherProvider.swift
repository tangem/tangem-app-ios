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

struct BlockcypherAddressResponse : Codable {
    let address: String?
    let balance: Int?
    let unconfirmed_balance: Int?
    let txrefs: [BlockcypherTxref]?
}

struct BlockcypherTxref: Codable {
    let tx_hash: String?
    let tx_output_n: Int?
    let value: Int64?
    let confirmations: Int64?
    let script: String?
}

struct BlockcypherFeeResponse: Codable {
    let low_fee_per_kb: Int64?
    let medium_fee_per_kb: Int64?
    let high_fee_per_kb: Int64?
}

class BlockcypherProvider: BitcoinNetworkProvider {    
    let provider = MoyaProvider<BlockcypherTarget>()
    let address: String
    let network: BitcoinNetwork
    
    init(address: String, isTestNet: Bool) {
        self.address = address
        self.network = isTestNet ? .test3: .main
    }
    
    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
        return provider.requestCombine(.address(address: self.address, network: self.network))
            .tryMap {response throws -> BitcoinResponse in
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
                
                let btcResponse = BitcoinResponse(balance: satoshiBalance, unconfirmed_balance: uncBalance, txrefs: txs)
                return btcResponse
        }
        .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return provider.requestCombine(.fee(network: self.network))
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
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.requestCombine(.send(txHex: transaction, network: self.network, accessToken: self.randomToken))
            .tryMap { response throws -> String in
                if let sendResponse = String(data: response.data, encoding: .utf8), sendResponse.count > 0{
                    return sendResponse
                } else {
                    throw "Empty respomse"
                }
        }
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


enum BitcoinNetwork: String {
    case main
    case test3
}

enum BlockcypherTarget: TargetType {
    case address(address:String, network: BitcoinNetwork)
    case fee(network: BitcoinNetwork)
    case send(txHex: String, network: BitcoinNetwork, accessToken: String)
    
    var baseURL: URL {
        switch self {
        case .address(_, let network):
            return baseUrl(network)
        case .fee(let network):
            return baseUrl(network)
        case .send(_, let network, _):
            return baseUrl(network)
        }
    }
    
    var path: String {
        switch self {
        case .address(let address, _):
            return "/addrs/\(address)?unspentOnly=true&includeScript=true"
        case .fee:
            return ""
        case .send(_, _, let token):
            return "/txs/push?token=\(token)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address:
            return .get
        case .fee:
            return .post
        case .send:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .send(let txHex):
            return .requestParameters(parameters: ["tx": txHex], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    private func baseUrl(_ network: BitcoinNetwork) -> URL {
        return URL(string: "https://api.blockcypher.com/v1/btc/\(network.rawValue)")!
    }
}
