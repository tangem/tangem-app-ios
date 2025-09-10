//
//  YieldModuleBottomSheetBottomBannerParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

enum YieldModuleBottomSheetBottomBannerParams {
    case notEnoughFeeCurrency(feeCurrencyName: String, tokenIcon: Image, buttonAction: () -> Void)
    case approveNeeded(buttonAction: () -> Void)
}
