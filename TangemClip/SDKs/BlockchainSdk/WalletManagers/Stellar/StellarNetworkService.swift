//
//  StellarNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.

import Foundation
import Combine

class StellarNetworkService {
    let stellarSdk: StellarSDK
    
    init(stellarSdk: StellarSDK) {
        self.stellarSdk = stellarSdk
    }
    
    public func getInfo(accountId: String, isAsset: Bool) -> AnyPublisher<StellarResponse, Error> {
        return stellarData(accountId: accountId)
            .tryMap{ (accountResponse, ledgerResponse) throws -> StellarResponse in
                guard let baseReserveStroops = Decimal(ledgerResponse.baseReserveInStroops),
                    let balance = Decimal(accountResponse.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE})?.balance) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                let sequence = accountResponse.sequenceNumber
                let assetBalances = try accountResponse.balances
                    .filter ({ $0.assetType != AssetTypeAsString.NATIVE })
                    .map { assetBalance -> StellarAssetResponse in
                        guard let code = assetBalance.assetCode,
                            let issuer = assetBalance.assetIssuer,
                            let balance = Decimal(assetBalance.balance) else {
                                throw WalletError.failedToParseNetworkResponse
                        }
                        
                        return StellarAssetResponse(code: code, issuer: issuer, balance: balance)
                }

                let divider =  Blockchain.stellar(testnet: false).decimalValue
                let baseReserve = baseReserveStroops / divider
                
                return StellarResponse(baseReserve: baseReserve,
                                       assetBalances: assetBalances,
                                       balance: balance,
                                       sequence: sequence)
        }
        .mapError { [unowned self] in self.mapError($0, isAsset: isAsset) }
        .eraseToAnyPublisher()
    }
    
    private func stellarData(accountId: String) -> AnyPublisher<(AccountResponse, LedgerResponse), Error> {
        Publishers.Zip(stellarSdk.accounts.getAccountDetails(accountId: accountId),
                       stellarSdk.ledgers.getLatestLedger())
            .eraseToAnyPublisher()
    }
    
    private func mapError(_ error: Error, isAsset: Bool? = nil) -> Error {
        if let horizonError = error as? HorizonRequestError {
            if case .notFound = horizonError, let isAsset = isAsset {
                return WalletError.noAccount(message: isAsset ? "no_account_xlm_asset".localized : "no_account_xlm".localized)
            } else {
                return horizonError.parseError()
            }
        } else {
            return error
        }
    }
}


struct StellarResponse {
    let baseReserve: Decimal
    let assetBalances: [StellarAssetResponse]
    let balance: Decimal
    let sequence: Int64
}

struct StellarAssetResponse {
    let code: String
    let issuer: String
    let balance: Decimal
}

struct StellarTargetAccountResponse {
    let accountCreated: Bool
    let trustlineCreated: Bool
}
