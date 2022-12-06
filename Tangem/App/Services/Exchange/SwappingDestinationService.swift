//
//  SwappingDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

struct SwappingDestinationService {
    private let walletModel: WalletModel
    private let preferTokens = ["USDT", "USDC"]
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
    
    func getDestination(source: Currency) async throws -> Currency {
        return source
    }
}
