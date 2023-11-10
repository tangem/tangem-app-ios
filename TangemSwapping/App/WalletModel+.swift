//
//  WalletModel+.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

extension WalletModel: ExpressWallet {
    var currency: TangemSwapping.ExpressCurrency {
        .init(
            contractAddress: ExpressConstants.coinContractAddress,
            network: tokenItem.networkId
        )
    }
    
    var address: String { defaultAddress }
    
    var decimalCount: Int {
        tokenItem.decimalCount
    }
    
    func getBalance() async throws -> Decimal {
        if let balanceValue {
            return balanceValue
        }
        
        _ = await self.update(silent: true).async()
        
        if let balanceValue {
            return balanceValue
        }
        
        throw ExpressManagerError.amountNotFound
    }
    
    func getCoinBalance() async throws -> Decimal {
        if let coinBalance = getDecimalBalance(for: .coin) {
            return coinBalance
        }
        
        _ = await self.update(silent: true).async()
        
        if let coinBalance = getDecimalBalance(for: .coin) {
            return coinBalance
        }
        
        throw ExpressManagerError.amountNotFound
    }
}
