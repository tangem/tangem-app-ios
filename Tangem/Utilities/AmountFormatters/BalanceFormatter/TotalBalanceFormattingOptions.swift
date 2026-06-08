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

    static let defaultOptions = TotalBalanceFormattingOptions(
        integerPartFont: Fonts.Regular.title1,
        fractionalPartFont: Fonts.Bold.title3,
        integerPartColor: Colors.Text.primary1,
        fractionalPartColor: Colors.Text.primary1,
        fractionalPartIncludesDecimalSeparator: false
    )

    static let defaultOptionsRedesign = TotalBalanceFormattingOptions(
        integerPartFont: .Tangem.Title44.semibold,
        fractionalPartFont: .Tangem.Heading28.regular,
        integerPartColor: .Tangem.Text.Neutral.primary,
        fractionalPartColor: .Tangem.Text.Neutral.primary,
        fractionalPartIncludesDecimalSeparator: true
    )

    static let navigationBarRedesign = TotalBalanceFormattingOptions(
        integerPartFont: Font.Tangem.Body16.medium,
        fractionalPartFont: Font.Tangem.Body16.medium,
        integerPartColor: Color.Tangem.Text.Neutral.primary,
        fractionalPartColor: Color.Tangem.Text.Neutral.secondary,
        fractionalPartIncludesDecimalSeparator: true
    )
}
