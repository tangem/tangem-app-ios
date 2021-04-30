//
//  EthereumNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON
//import web3swift
import BigInt

class EthereumNetworkService {
    private let network: EthereumNetwork
    private let provider = MoyaProvider<InfuraTarget>(
//        plugins: [NetworkLoggerPlugin()]
    )

    private let blockcypherProvider: BlockcypherNetworkProvider?
    private let blockchairProvider: BlockchairNetworkProvider?
    
    init(network: EthereumNetwork, blockcypherProvider: BlockcypherNetworkProvider?, blockchairProvider: BlockchairNetworkProvider?) {
        self.network = network
        self.blockcypherProvider = blockcypherProvider
        self.blockchairProvider = blockchairProvider
    }
    
    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumResponse, Error> {
        if !tokens.isEmpty {
            return tokenData(address: address, tokens: tokens)
                .map { return EthereumResponse(balance: $0.0, tokenBalances: $0.1, txCount: $0.2, pendingTxCount: $0.3) }
                .eraseToAnyPublisher()
        } else {
            return coinData(address: address)
                .map { return EthereumResponse(balance: $0.0, tokenBalances: [:], txCount: $0.1, pendingTxCount: $0.2) }
                .eraseToAnyPublisher()
        }
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] token in
                self.getTokenBalance(address, contractAddress: token.contractAddress, tokenDecimals: token.decimalCount)
                    .replaceError(with: -1)
                    .setFailureType(to: Error.self)
                    .filter { $0 >= 0 }
                    .map { (token, $0) }
            }
            .collect()
            .map { $0.reduce(into: [Token: Decimal]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }
    
    func findErc20Tokens(address: String) -> AnyPublisher<[BlockchairToken], Error> {
        guard let blockchairProvider = blockchairProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
        return blockchairProvider.findErc20Tokens(address: address)
    }
    
	// MARK: - Private functions
    
    private func tokenData(address: String, tokens: [Token]) -> AnyPublisher<(Decimal,[Token:Decimal],Int,Int), Error> {
        return Publishers.Zip4(getBalance(address),
                               getTokensBalance(address, tokens: tokens),
                               getTxCount(address),
                               getPendingTxCount(address))
            .eraseToAnyPublisher()
    }
    
    private func coinData(address: String) -> AnyPublisher<(Decimal,Int,Int), Error> {
        return Publishers.Zip3(getBalance(address),
                               getTxCount(address),
                               getPendingTxCount(address))
            .eraseToAnyPublisher()
    }
    
    private func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        return getTxCount(target: .transactions(address: address, network: network))
    }
    
    private func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        return getTxCount(target: .pending(address: address, network: network))
    }
    
    private func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        return provider
            .requestPublisher(.balance(address: address, network: network))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap {[unowned self] in try self.parseBalance($0.data, decimalsCount: network.blockchain.decimalCount)}
            .eraseToAnyPublisher()
    }
    
    private func getTokenBalance(_ address: String, contractAddress: String, tokenDecimals: Int) -> AnyPublisher<Decimal, Error> {
        return provider
            .requestPublisher(.tokenBalance(address: address, contractAddress: contractAddress, network: network ))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap{[unowned self] in try self.parseBalance($0.data, decimalsCount: tokenDecimals)}
            .eraseToAnyPublisher()
    }
    
    private func getTxCount(target: InfuraTarget) -> AnyPublisher<Int, Error> {
        return provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap {[unowned self] in try self.parseTxCount($0.data)}
            .eraseToAnyPublisher()
    }
    
    private func parseResult(_ data: Data) throws -> String {
        let balanceInfo = JSON(data)
        if let result = balanceInfo["result"].string {
            return result
        }
        
        throw WalletError.failedToParseNetworkResponse
    }
    
    private func parseTxCount(_ data: Data) throws -> Int {
        let countString = try parseResult(data)
        guard let count = Int(countString.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseTxCount
        }
        
        return count
    }
    
    private func parseBalance(_ data: Data, decimalsCount: Int) throws -> Decimal {
        try EthereumUtils.parseEthereumDecimal(try parseResult(data), decimalsCount: decimalsCount)
    }
}

struct EthereumResponse {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let txCount: Int
    let pendingTxCount: Int
}
