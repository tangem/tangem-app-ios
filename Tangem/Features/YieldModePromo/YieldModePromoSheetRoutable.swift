//
//  YieldModePromoSheetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol YieldModePromoSheetRoutable: AnyObject {
    func presentYieldModePromo(_ viewModel: YieldModePromoSheetViewModel)
    func dismissYieldModePromo()
    func openYieldModeEarn()
}
