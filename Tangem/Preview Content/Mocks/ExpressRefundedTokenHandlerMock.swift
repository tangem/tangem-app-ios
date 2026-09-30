//
//  ExpressRefundedTokenHandlerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

struct ExpressRefundedTokenHandlerMock: ExpressRefundedTokenHandler {
    func handle(blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency, userWalletId: UserWalletId) async throws -> TokenItem {
        return .blockchain(.init(.polygon(testnet: false), derivationPath: nil))
    }
}
