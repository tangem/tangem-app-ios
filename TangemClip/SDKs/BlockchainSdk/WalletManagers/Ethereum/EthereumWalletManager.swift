//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import Moya

public enum ETHError: String, Error, LocalizedError {
    case failedToParseTxCount = "eth_tx_count_parse_error"
    case failedToParseBalance = "eth_balance_parse_error"
    case failedToParseTokenBalance = "eth_token_balance_parse_error"
    case failedToParseGasLimit
    case unsupportedFeature
    
    public var errorDescription: String? {
        switch self {
        case .failedToParseGasLimit:
            return rawValue
        default:
            return rawValue.localized
        }
    }
}

class EthereumWalletManager: WalletManager {
    var networkService: EthereumNetworkService!
    var txCount: Int = -1
    var pendingTxCount: Int = -1
    
    private var gasLimit: BigUInt? = nil
    private var findTokensSubscription: AnyCancellable? = nil
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    override public func addToken(_ token: Token) -> AnyPublisher<Amount, Error> {
        if !cardTokens.contains(token) {
            cardTokens.append(token)
        }
        
        return networkService.getTokensBalance(wallet.address, tokens: [token])
            .tryMap { [unowned self] result throws -> Amount in
                guard let value = result[token] else {
                    throw WalletError.failedToLoadTokenBalance(token: token)
                }
                let tokenAmount = wallet.add(tokenValue: value, for: token)
                return tokenAmount
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(with response: EthereumResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }
        txCount = response.txCount
        pendingTxCount = response.pendingTxCount
        if txCount == pendingTxCount {
            for  index in wallet.transactions.indices {
                wallet.transactions[index].status = .confirmed
            }
        } else {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        }
    }
}


extension EthereumWalletManager: ThenProcessable { }

extension EthereumWalletManager {
    enum GasLimit: Int {
        case `default` = 21000
        case erc20 = 60000
        case medium = 150000
        case high = 300000
        
        var value: BigUInt {
            return BigUInt(self.rawValue)
        }
    }
}

extension EthereumWalletManager: TokenFinder {
    func findErc20Tokens(completion: @escaping (Result<Bool, Error>)-> Void) {
        findTokensSubscription?.cancel()
        findTokensSubscription = networkService
            .findErc20Tokens(address: wallet.address)
            .sink(receiveCompletion: { subscriptionCompletion in
                if case let .failure(error) = subscriptionCompletion {
                    completion(.failure(error))
                    return
                }
            }, receiveValue: {[unowned self] blockchairTokens in
                if blockchairTokens.isEmpty {
                    completion(.success(false))
                    return
                }

                var tokensAdded = false
                blockchairTokens.forEach { blockchairToken in
                    let token = Token(blockchairToken)
                    if !self.cardTokens.contains(token) {
                        self.cardTokens.append(token)
                        let balanceValue = Decimal(blockchairToken.balance) ?? 0
                        let balanceWeiValue = balanceValue / pow(Decimal(10), blockchairToken.decimals)
                        self.wallet.add(tokenValue: balanceWeiValue, for: token)
                        tokensAdded = true
                    }
                }

                completion(.success(tokensAdded))
            })
    }
}
