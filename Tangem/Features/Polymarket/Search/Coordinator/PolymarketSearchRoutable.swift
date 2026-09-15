//
//  PolymarketSearchRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketSearchRoutable: AnyObject {
    func openEventDetailsFromSearch(eventID: String)

    func openOrderFromSearch(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String)
}
