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
        integerPartColor: Color,
        fractionalPartColor: Color,
        fractionalPartIncludesDecimalSeparator: Bool
    ) {
        integerPart = AttributedBalanceFormatter.PartStyle(token: integerPartFont, color: integerPartColor)
        fractionalPart = AttributedBalanceFormatter.PartStyle(token: fractionalPartFont, color: fractionalPartColor)
        self.fractionalPartIncludesDecimalSeparator = fractionalPartIncludesDecimalSeparator
    }

    static var defaultOptionsRedesign: TotalBalanceFormattingOptions {
        .init(
            integerPartFont: DesignSystem.Font.displayMediumToken,
            fractionalPartFont: DesignSystem.Font.headingMediumToken,
            integerPartColor: DesignSystem.Color.textPrimary,
            fractionalPartColor: DesignSystem.Color.textSecondary,
            fractionalPartIncludesDecimalSeparator: true
        )
    }

    static var mainHeaderRedesign: TotalBalanceFormattingOptions {
        TotalBalanceFormattingOptions(
            integerPartFont: DesignSystem.Font.displayMediumToken,
            fractionalPartFont: DesignSystem.Font.headingMediumToken,
            integerPartColor: DesignSystem.Color.textPrimary,
            fractionalPartColor: DesignSystem.Color.textPrimary,
            fractionalPartIncludesDecimalSeparator: true
        )
    }
}
