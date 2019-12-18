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
    
    public func getInfo(accountId: String, assetCode: String?) -> AnyPublisher<StellarResponse, Error> {
        return Publishers.Zip(stellarSdk.accounts.getAccountDetails(accountId: accountId),
                              stellarSdk.ledgers.getLatestLedger())
            .tryMap({ response throws -> StellarResponse in
                guard let baseFeeStroops = Decimal(response.1.baseFeeInStroops),
                    let baseReserveStroops = Decimal(response.1.baseReserveInStroops),
                    let balance = Decimal(response.0.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE})?.balance) else {
                        throw StellarError.requestFailed
                }
                
                let sequence = response.0.sequenceNumber
                let assetBalance = Decimal(assetCode == nil ? nil : response.0.balances.first(where: {$0.assetType != AssetTypeAsString.NATIVE && $0.assetCode == assetCode!})?.balance)
                
                let divider =  Decimal(10000000)
                let baseFee = baseFeeStroops/divider
                let baseReserve = baseReserveStroops/divider
                
                return StellarResponse(baseFee: baseFee, baseReserve: baseReserve, assetBalance: assetBalance, balance: balance, sequence: sequence)
            })
            .eraseToAnyPublisher()
    }
}


struct StellarResponse {
    let baseFee: Decimal
    let baseReserve: Decimal
    let assetBalance: Decimal?
    let balance: Decimal
    let sequence: Int64
}
