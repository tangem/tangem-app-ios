//
//  XRPWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdkClips

public enum XRPError: String, Error, LocalizedError {
    case failedLoadUnconfirmed = "xrp_load_unconfirmed_error"
    case failedLoadReserve = "xrp_load_reserve_error"
    case failedLoadInfo = "xrp_load_account_error"
    case missingReserve = "xrp_missing_reserve_error"
    case distinctTagsFound
    
    public var errorDescription: String? {
        switch self {
        case .distinctTagsFound:
            return rawValue
        default:
            return rawValue.localized
        }
    }
}

class XRPWalletManager: WalletManager {
    var networkService: XRPNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(account: wallet.address)
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
    
    private func updateWallet(with response: XrpInfoResponse) {
        wallet.add(reserveValue: response.reserve/Decimal(1000000))
        wallet.add(coinValue: (response.balance - response.reserve)/Decimal(1000000))
        
        if response.balance != response.unconfirmedBalance {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
}

extension XRPWalletManager: ThenProcessable { }
