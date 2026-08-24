//
//  AddWalletTypeSelectorSheetOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol AddWalletTypeSelectorSheetOutput: AnyObject {
    func addWalletTypeSelectorDidRequestHardwareWallet()
    func addWalletTypeSelectorDidRequestMobileWallet()
}
