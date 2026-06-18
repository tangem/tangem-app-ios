//
//  TotalBalanceFormattingOptions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TotalBalanceFormattingOptions {
    let integerPartFont: TangemFontStyle
    let fractionalPartFont: TangemFontStyle
    let integerPartColor: Color
    let fractionalPartColor: Color
    let fractionalPartIncludesDecimalSeparator: Bool

    static var defaultOptions: TotalBalanceFormattingOptions {
        .init(
            integerPartFont: TangemFontStyle(font: Fonts.Regular.title1),
            fractionalPartFont: TangemFontStyle(font: Fonts.Bold.title3),
            integerPartColor: Colors.Text.primary1,
            fractionalPartColor: Colors.Text.primary1,
            fractionalPartIncludesDecimalSeparator: false
        )
    }

    static var defaultOptionsRedesign: TotalBalanceFormattingOptions {
        .init(
            integerPartFont: Font.Tangem.Title44.semibold,
            fractionalPartFont: Font.Tangem.Heading28.semibold,
            integerPartColor: .Tangem.Text.Neutral.primary,
            fractionalPartColor: .Tangem.Text.Neutral.primary,
            fractionalPartIncludesDecimalSeparator: true
        )
    }
}
