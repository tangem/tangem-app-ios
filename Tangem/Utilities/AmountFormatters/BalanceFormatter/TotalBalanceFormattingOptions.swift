//
//  TotalBalanceFormattingOptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TotalBalanceFormattingOptions {
    let integerPart: AttributedBalanceFormatter.PartStyle
    let fractionalPart: AttributedBalanceFormatter.PartStyle
    let fractionalPartIncludesDecimalSeparator: Bool

    init(
        integerPartFont: TangemTypographyToken,
        fractionalPartFont: TangemTypographyToken,
        color: Color,
        fractionalPartIncludesDecimalSeparator: Bool
    ) {
        integerPart = AttributedBalanceFormatter.PartStyle(token: integerPartFont, color: color)
        fractionalPart = AttributedBalanceFormatter.PartStyle(token: fractionalPartFont, color: color)
        self.fractionalPartIncludesDecimalSeparator = fractionalPartIncludesDecimalSeparator
    }

    static var mainHeaderRedesign: TotalBalanceFormattingOptions {
        TotalBalanceFormattingOptions(
            integerPartFont: DesignSystem.Font.displayMediumToken,
            fractionalPartFont: DesignSystem.Font.headingMediumToken,
            color: DesignSystem.Color.textPrimary,
            fractionalPartIncludesDecimalSeparator: true
        )
    }
}
