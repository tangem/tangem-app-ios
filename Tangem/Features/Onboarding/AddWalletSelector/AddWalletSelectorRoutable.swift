//
//  AddWalletSelectorRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol AddWalletSelectorRoutable: AnyObject {
    func openAddHardwareWallet()
    func openAddMobileWallet(source: MobileCreateWalletSource)
}
