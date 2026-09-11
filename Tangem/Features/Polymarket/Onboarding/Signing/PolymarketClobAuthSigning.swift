//
//  PolymarketClobAuthSigning.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketClobAuthSigning {
    func sign() async throws(PolymarketSigningError) -> PolymarketCLOBAuthHeaders
}
