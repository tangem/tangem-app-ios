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
    let integerPartFont: Font
    let fractionalPartFont: Font
    let integerPartColor: Color
    let fractionalPartColor: Color
    let fractionalPartIncludesDecimalSeparator: Bool

    static var defaultOptions: TotalBalanceFormattingOptions {
        .init(
            integerPartFont: Fonts.Regular.title1,
            fractionalPartFont: Fonts.Bold.title3,
            integerPartColor: Colors.Text.primary1,
            fractionalPartColor: Colors.Text.primary1,
            fractionalPartIncludesDecimalSeparator: false
        )
    }

    static var defaultOptionsRedesign: TotalBalanceFormattingOptions {
        .init(
            integerPartFont: .Tangem.Custom.titleRegular44,
            fractionalPartFont: .Tangem.Heading28.regular,
            integerPartColor: .Tangem.Text.Neutral.primary,
            fractionalPartColor: .Tangem.Text.Neutral.primary,
            fractionalPartIncludesDecimalSeparator: true
        )
    }
}
