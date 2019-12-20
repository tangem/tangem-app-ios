//
//  EthereumNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON

class EthereumNetworkManager {
    let provider = MoyaProvider<EthereumTarget>()
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.requestCombine(.send(transaction: transaction))
            .tryMap {[unowned self] response throws -> String in
                if let hash = try? self.parseResult(response.data),
                                       hash.count > 0 {
                                      return hash
                                   }
                                    throw "Empty response"
        }
        .eraseToAnyPublisher()
    }
    
    func getInfo(address: String, contractAddress: String?) -> AnyPublisher<EthereumResponse, Error> {
        if let contractAddress = contractAddress {
            return Publishers.Zip4(getBalance(address),
                                   getTokenBalance(address, contractAddress: contractAddress),
                                   getTxCount(address),
                                   getPendingTxCount(address))
                .map {
                    return EthereumResponse(balance: $0.0, tokenBalance: $0.1, txCount: $0.2, pendingTxCount: $0.3)
            }
            .eraseToAnyPublisher()
        } else {
            return Publishers.Zip3(getBalance(address),
                                   getTxCount(address),
                                   getPendingTxCount(address))
                .map {
                    return EthereumResponse(balance: $0.0, tokenBalance: nil, txCount: $0.1, pendingTxCount: $0.2)
            }
            .eraseToAnyPublisher()
        }
    }
    
    private func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        return getTxCount(target: .transactions(address: address))
    }
    
    private func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        return getTxCount(target: .pending(address: address))
    }
    //[REDACTED_TODO_COMMENT]
    private func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        
        let future = Future<Decimal, Error>() {[unowned self] promise in
            self.provider.request(.balance(address: address)) {[unowned self] result in
                switch result {
                case .success(let response):
                    do {
                        let balanceEth = try self.parseBalance(response.data)
                        promise(.success(balanceEth))
                    } catch {
                        promise(.failure(error))
                    }
                case .failure(let moyaError):
                    promise(.failure(moyaError))
                }
            }
        }
        return AnyPublisher(future)
    }
    
    private func getTokenBalance(_ address: String, contractAddress: String) -> AnyPublisher<Decimal, Error> {
        let future = Future<Decimal, Error>() {[unowned self] promise in
            self.provider.request(.tokenBalance(address: address, contractAddress: contractAddress, tokenNetwork: .eth )) {[unowned self]  result in
                switch result {
                case .success(let response):
                    do {
                        let balanceEth = try self.parseBalance(response.data)
                        promise(.success(balanceEth))
                    } catch {
                        promise(.failure(error))
                    }
                case .failure(let moyaError):
                    promise(.failure(moyaError))
                }
            }
        }
        return AnyPublisher(future)
    }
    
    private func getTxCount(target: EthereumTarget) -> AnyPublisher<Int, Error> {
        let future = Future<Int, Error> {[unowned self] promise in
            self.provider.request(target) {[unowned self] result in
                switch result {
                case .success(let response):
                    do {
                        let txCount = try self.parseTxCount(response.data)
                        promise(.success(txCount))
                    } catch {
                        promise(.failure(error))
                    }
                    break
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
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
