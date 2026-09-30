//
//  ExpressRefundedTokenHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

protocol ExpressRefundedTokenHandler {
    func handle(blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency, userWalletId: UserWalletId) async throws -> TokenItem
}
