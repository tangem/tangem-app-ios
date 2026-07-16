//
//  SwapAmountFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum SwapAmountFormatter {
    static func formatAmount(_ text: String, isApproximate: Bool) -> String {
        isApproximate ? "\(AppConstants.tildeSign)\(AppConstants.unbreakableSpace)\(text)" : text
    }
}
