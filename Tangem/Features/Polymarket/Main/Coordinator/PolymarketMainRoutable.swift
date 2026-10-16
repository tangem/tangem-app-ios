//
//  PolymarketMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketMainRoutable: AnyObject {
    func dismiss()
    func openRegionWarning()

    @MainActor
    func openHowItWorks()

    @MainActor
    func openSupportChat()
}

typealias PolymarketMainScreenRoutable = PolymarketMainRoutable
    & PolymarketBalanceBlockRoutable
    & PolymarketPositionsBlockRoutable
    & PolymarketEventOpeningRoutable
