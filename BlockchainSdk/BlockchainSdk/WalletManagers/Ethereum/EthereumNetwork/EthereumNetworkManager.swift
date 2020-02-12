//
//  EthereumNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import RxSwift
import Combine
import SwiftyJSON

class EthereumNetworkManager {
    let network: InfuraNetwork = .eth
    let provider = MoyaProvider<InfuraTarget>()
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.requestCombine(.send(transaction: transaction, network: network))
            .tryMap {[unowned self] response throws -> String in
                if let hash = try? self.parseResult(response.data),
                                       hash.count > 0 {
                                      return hash
                                   }
                                    throw "Empty response"
        }
        .eraseToAnyPublisher()
    }
    
    func getInfo(address: String, contractAddress: String?) -> Single<EthereumResponse> {
        if let contractAddress = contractAddress {
            return tokenData(address: address, contractAddress: contractAddress)
                .map { return EthereumResponse(balance: $0.0, tokenBalance: $0.1, txCount: $0.2, pendingTxCount: $0.3) }
        } else {
            return coinData(address: address)
                .map { return EthereumResponse(balance: $0.0, tokenBalance: nil, txCount: $0.1, pendingTxCount: $0.2) }
        }
    }
    
    private func tokenData(address: String, contractAddress: String) -> Single<(Decimal,Decimal,Int,Int)> {
        return Single.zip(getBalance(address),
                              getTokenBalance(address, contractAddress: contractAddress),
                              getTxCount(address),
                              getPendingTxCount(address))
    }
    
    private func coinData(address: String) -> Single<(Decimal,Int,Int)> {
        return Single.zip(getBalance(address),
                          getTxCount(address),
                          getPendingTxCount(address))
    }
    
    private func getTxCount(_ address: String) -> Single<Int> {
        return getTxCount(target: .transactions(address: address, network: network))
    }
    
    private func getPendingTxCount(_ address: String) -> Single<Int> {
        return getTxCount(target: .pending(address: address, network: network))
    }

    private func getBalance(_ address: String) -> Single<Decimal> {
        return provider
            .rx
            .request(.balance(address: address, network: network))
            .map {[unowned self] in try self.parseBalance($0.data)}
    }
    
    private func getTokenBalance(_ address: String, contractAddress: String) -> Single<Decimal> {
        return provider
            .rx
            .request(.tokenBalance(address: address, contractAddress: contractAddress, network: .eth ))
            .map{[unowned self] in try self.parseBalance($0.data)}
    }
    
    private func getTxCount(target: InfuraTarget) -> Single<Int> {
        return provider
            .rx
            .request(target)
            .map {[unowned self] in try self.parseTxCount($0.data)}
    }
    
    private func parseResult(_ data: Data) throws -> String {
        let balanceInfo = JSON(data)
        if let result = balanceInfo["result"].string {
            return result
        }

        throw "Failed to parse result"
    }
    
    private func parseTxCount(_ data: Data) throws -> Int {
        let countString = try parseResult(data)
        guard let count = Int(countString.removeHexPrefix(), radix: 16) else {
            throw "Failed to parse count"
        }
        
        return count
    }
    
    private func parseBalance(_ data: Data) throws -> Decimal {
        let quantity = try parseResult(data)
        let balanceData = Data(hex: quantity)
        guard let balanceWei = Decimal(data: balanceData) else {
            throw "Failed to convert the quantity"
        }
        
        let balanceEth = balanceWei / Decimal(1000000000000000000)
        return balanceEth
    }
}

struct EthereumResponse {
    let balance: Decimal
    let tokenBalance: Decimal?
    let txCount: Int
    let pendingTxCount: Int
}
