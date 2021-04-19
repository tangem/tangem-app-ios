//
//  TezosWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdkClips

class TezosWalletManager: WalletManager {
    var networkService: TezosNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address)
            .sink(receiveCompletion: {[unowned self]  completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
                }, receiveValue: { [unowned self] response in
                    self.updateWallet(with: response)
                    completion(.success(()))
            })
    }
    
    private func updateWallet(with response: TezosAddress) {
        
        if response.balance != wallet.amounts[.coin]?.value {
            wallet.transactions = []
        }
        
        wallet.add(coinValue: response.balance)
    }
}


extension TezosWalletManager: ThenProcessable { }
//
