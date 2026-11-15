//
//  LendingPositionRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol LendingPositionRoutable: AnyObject {
    func openWithdraw(position: Decimal)
    func openAddFunds()
    func openHowItWorks()
    func openURL(_ url: URL)
    func closeLendingPosition()
}
