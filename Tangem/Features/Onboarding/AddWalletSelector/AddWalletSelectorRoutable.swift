//
//  AddWalletSelectorRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol AddWalletSelectorRoutable: AnyObject {
    func openAddHardwareWallet()
    func openAddMobileWallet(source: MobileCreateWalletSource)
}
