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
import RxSwift

class StellarNetworkManager {
    let stellarSdk: StellarSDK
    
//    let account = PassthroughSubject<AccountResponse, Error>()
//    let ledger = PassthroughSubject<LedgerResponse, Error>()
    
    init(stellarSdk: StellarSDK) {
        self.stellarSdk = stellarSdk
    }
    
    @available(iOS 13.0, *)
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
    
    public func getInfo(accountId: String, assetCode: String?) -> Single<StellarResponse> {
        return stellarData(accountId: accountId)
            .map({ (accountResponse, ledgerResponse) throws -> StellarResponse in
                guard let baseFeeStroops = Decimal(ledgerResponse.baseFeeInStroops),
                    let baseReserveStroops = Decimal(ledgerResponse.baseReserveInStroops),
                    let balance = Decimal(accountResponse.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE})?.balance) else {
                        throw StellarError.requestFailed
                }
                
                let sequence = accountResponse.sequenceNumber
                let assetBalance = Decimal(assetCode == nil ? nil : accountResponse.balances.first(where: {$0.assetType != AssetTypeAsString.NATIVE && $0.assetCode == assetCode!})?.balance)
                
                let divider =  Decimal(10000000)
                let baseFee = baseFeeStroops/divider
                let baseReserve = baseReserveStroops/divider
                
                return StellarResponse(baseFee: baseFee, baseReserve: baseReserve, assetBalance: assetBalance, balance: balance, sequence: sequence)
            })
    }
    
    private func stellarData(accountId: String) -> Single<(AccountResponse, LedgerResponse)> {
        return Observable.zip(
            stellarSdk.accounts.getAccountDetails(accountId: accountId),
            stellarSdk.ledgers.getLatestLedger())
            .asSingle()
    }
}


struct StellarResponse {
    let baseFee: Decimal
    let baseReserve: Decimal
    let assetBalance: Decimal?
    let balance: Decimal
    let sequence: Int64
}
