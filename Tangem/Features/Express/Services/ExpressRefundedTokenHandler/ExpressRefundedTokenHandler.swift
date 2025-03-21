//
//  ExpressRefundedTokenHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol ExpressRefundedTokenHandler {
    func handle(expressCurrency: ExpressCurrency) async throws -> TokenItem
}
