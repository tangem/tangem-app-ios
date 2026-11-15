//
//  EarnYieldPickerRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol EarnYieldPickerRoutable: AnyObject {
    func openStartEarning(for product: EarnYieldPickerProduct)
    func openAddFunds()
    func openIncentiveInfo(for product: EarnYieldPickerProduct)
    func openURL(_ url: URL)
    func dismissYieldPicker()
}
