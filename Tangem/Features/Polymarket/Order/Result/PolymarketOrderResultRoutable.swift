//
//  PolymarketOrderResultRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketOrderResultRoutable: AnyObject {
    func closeOrder()

    func openPosition(_ position: PolymarketPosition)
}
