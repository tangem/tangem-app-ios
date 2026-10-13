//
//  MobileRemoveSocialWalletRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileRemoveSocialWalletRoutable: AnyObject {
    func removeSocialWalletClose()
    func removeSocialWalletCompleted()
}
