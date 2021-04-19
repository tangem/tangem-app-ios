//
//  BinanceWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

//import Foundation
//import Combine
//import BinanceChain
//import struct TangemSdkClips.SignResponse
//
//class BinanceWalletManager: WalletManager {
//    var networkService: BinanceNetworkService!
//    private var latestTxDate: Date?
//    
//    override func update(completion: @escaping (Result<Void, Error>)-> Void) {//check it
//        cancellable = networkService
//            .getInfo(address: wallet.address)
//            .sink(receiveCompletion: {[unowned self] completionSubscription in
//                if case let .failure(error) = completionSubscription {
//                    self.wallet.amounts = [:]
//                    completion(.failure(error))
//                }
//            }, receiveValue: { [unowned self] response in
//                self.updateWallet(with: response)
//                completion(.success(()))
//            })
//    }
//    
//    private func updateWallet(with response: BinanceInfoResponse) {
//        let coinBalance = response.balances[wallet.blockchain.currencySymbol] ?? 0 //if withdrawal all funds, there is no balance from network
//        wallet.add(coinValue: coinBalance)
//        
//        if cardTokens.isEmpty {
//            _ = response.balances
//                .filter { $0.key != wallet.blockchain.currencySymbol }
//                .map { (Token(symbol: $0.key.split(separator: "-").first.map {String($0)} ?? $0.key,
//                              contractAddress: $0.key,
//                              decimalCount: wallet.blockchain.decimalCount),
//                        $0.value) }
//                .map { token, balance in
//                    wallet.add(tokenValue: balance, for: token)
//            }
//        } else {
//            for token in cardTokens {
//                let balance = response.balances[token.contractAddress] ?? 0 //if withdrawal all funds, there is no balance from network
//                wallet.add(tokenValue: balance, for: token)
//            }
//        }
//        
//        let currentDate = Date()
//        for  index in wallet.transactions.indices {
//            if DateInterval(start: wallet.transactions[index].date!, end: currentDate).duration > 10 {
//                wallet.transactions[index].status = .confirmed
//            }
//        }
//    }
//}
//
//extension BinanceWalletManager: ThenProcessable { }
