//
//  CardanoWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public enum CardanoError: String, Error, LocalizedError {
    case noUnspents = "cardano_missing_unspents"
    case lowAda = "cardano_low_ada"
     
    public var errorDescription: String? {
        return self.rawValue.localized
    }
}

class CardanoWalletManager: WalletManager {
    var networkService: CardanoNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {//check it
        cancellable = networkService
            .getInfo(addresses: wallet.addresses.map { $0.value })
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

    private func updateWallet(with response: CardanoAddressResponse) {
        wallet.add(coinValue: response.balance)
        
        wallet.transactions = wallet.transactions.map {
            var mutableTx = $0
            if response.recentTransactionsHashes.isEmpty {
                if response.unspentOutputs.isEmpty ||
                   response.unspentOutputs.first(where: { $0.transactionHash == mutableTx.hash }) != nil {
                    mutableTx.status = .confirmed
                }
            } else {
                if response.recentTransactionsHashes.first(where: { $0 == mutableTx.hash }) != nil {
                    mutableTx.status = .confirmed
                }
            }
            return mutableTx
        }
    }
}

extension CardanoWalletManager: ThenProcessable { }

