//
//  AddWalletSheetDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol AddWalletSheetDelegate: AnyObject {
    func didSelect(option: AddWalletSheetOption)
    func didClose()
}
