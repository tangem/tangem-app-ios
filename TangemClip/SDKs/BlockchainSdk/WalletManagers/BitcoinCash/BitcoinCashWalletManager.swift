//
//  BitcoinCashWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips
import Combine

class BitcoinCashWalletManager: WalletManager {
    var networkService: BitcoinCashNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: self.wallet.address)
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
    
    private func updateWallet(with response: BitcoinResponse) {
        wallet.add(coinValue: response.balance)
        if response.hasUnconfirmed {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
}

extension BitcoinCashWalletManager: ThenProcessable { }
