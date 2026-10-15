//
//  PolymarketBalanceBlockRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketBalanceBlockRoutable: AnyObject {
    func openAddFunds()
    func openWithdraw()
    func openRegionWarning()
}
