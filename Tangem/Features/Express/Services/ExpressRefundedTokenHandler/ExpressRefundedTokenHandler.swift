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
    func handle(userWalletId: UserWalletId?, blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency) async throws -> TokenItem
}
