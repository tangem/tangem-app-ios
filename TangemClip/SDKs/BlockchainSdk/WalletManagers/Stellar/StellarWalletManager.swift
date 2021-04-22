//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import Combine

public enum StellarError: String, Error, LocalizedError {
    case emptyResponse = "xlm_empty_response_error"
    case requiresMemo = "xlm_requires_memo_error"
    case failedToFindLatestLedger = "xlm_latest_ledger_error"
    case xlmCreateAccount = "no_account_xlm"
    case assetCreateAccount = "no_account_xlm_asset"
    case assetNoAccountOnDestination = "no_account_on_destination_xlm_asset"
    case assetNoTrustline = "no_trustline_xlm_asset"

    public var errorDescription: String? {
        return self.rawValue.localized
    }
}

class StellarWalletManager: WalletManager {
    var networkService: StellarNetworkService!
    var stellarSdk: StellarSDK!

    override func update(completion: @escaping (Result<(), Error>)-> Void)  {
        cancellable = networkService
            .getInfo(accountId: wallet.address, isAsset: !cardTokens.isEmpty)
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

    private func updateWallet(with response: StellarResponse) {
        let fullReserve = response.assetBalances.isEmpty ? response.baseReserve * 2 : response.baseReserve * 3
        wallet.add(reserveValue: fullReserve)
        wallet.add(coinValue: response.balance - fullReserve)

        if cardTokens.isEmpty {
            _ = response.assetBalances
                .map { (Token(symbol: $0.code,
                              contractAddress: $0.issuer,
                              decimalCount: wallet.blockchain.decimalCount),
                        $0.balance) }
                .map { token, balance in
                    wallet.add(tokenValue: balance, for: token)
            }
        } else {
            for token in cardTokens {
                let assetBalance = response.assetBalances.first(where: { $0.code == token.symbol })?.balance ?? 0.0
                wallet.add(tokenValue: assetBalance, for: token)

            }
        }
        let currentDate = Date()
        for  index in wallet.transactions.indices {
            if DateInterval(start: wallet.transactions[index].date!, end: currentDate).duration > 10 {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
}

extension StellarWalletManager: ThenProcessable { }
