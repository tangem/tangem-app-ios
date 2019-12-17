//
//  StellarNetworkManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine

class StellarNetwotkManager {
    let stellarSdk: StellarSDK
    
    let account = PassthroughSubject<AccountResponse, Error>()
    let ledger = PassthroughSubject<LedgerResponse, Error>()
    
    init(stellarSdk: StellarSDK) {
        self.stellarSdk = stellarSdk
    }
    
    public func send(transaction: String) -> AnyPublisher<Bool, Error> {
        return stellarSdk.transactions.postTransaction(transactionEnvelope: transaction)
            .tryMap{ submitTransactionResponse throws  -> Bool in
                if submitTransactionResponse.transactionResult.code == .success {
                    return true
                } else {
                    throw "Result code: \(submitTransactionResponse.transactionResult.code)"
                }
        }
        .eraseToAnyPublisher()
    }
    
    public func getInfo(accountId: String) -> AnyPublisher<(AccountResponse, LedgerResponse), Error> {
        return Publishers.Zip(stellarSdk.accounts.getAccountDetails(accountId: accountId),
                              stellarSdk.ledgers.getLatestLedger()).eraseToAnyPublisher()
    }
}
