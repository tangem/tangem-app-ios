//
//  LegacyTypographyShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUIUtils

struct LegacyTypographyShowcase: View {
    @State private var family: Family = .regular
    @State private var textStyle: TextStyle = .body
    @State private var text = "Send 0.04817 BTC to bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
    @State private var highlightsBounds = true

    var body: some View {
        DSShowcase("Typography (legacy)") { controls in
            controls.picker("Family", $family)
            controls.picker("Style", $textStyle)
            controls.text("Text", $text)
            controls.toggle("Highlight bounds", $highlightsBounds)
            controls.note("Static families ignore Dynamic Type.")
        } stage: {
            sample(text, font: family.font(textStyle))
        } matrix: {
            DSShowcaseMatrix(rows: TextStyle.allCases, columns: Family.allCases) { textStyle, family in
                sample("Tangem Wallet", font: family.font(textStyle))
            }
        }
    }

    private func sample(_ text: String, font: Font) -> some View {
        Text(text)
            .style(font, color: Colors.Text.primary1)
            .background(highlightsBounds ? Color.red.opacity(0.25) : Color.clear)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension LegacyTypographyShowcase {
    enum Family: CaseIterable {
        case regular
        case bold
        case regularStatic
        case boldStatic

        func font(_ textStyle: TextStyle) -> Font {
            fonts[textStyle.rawValue]
        }

        private var fonts: [Font] {
            switch self {
            case .regular:
                [
                    Fonts.Regular.largeTitle,
                    Fonts.Regular.title1,
                    Fonts.Regular.title2,
                    Fonts.Regular.title3,
                    Fonts.Regular.headline,
                    Fonts.Regular.body,
                    Fonts.Regular.callout,
                    Fonts.Regular.subheadline,
                    Fonts.Regular.footnote,
                    Fonts.Regular.caption1,
                    Fonts.Regular.caption2,
                ]
            case .bold:
                [
                    Fonts.Bold.largeTitle,
                    Fonts.Bold.title1,
                    Fonts.Bold.title2,
                    Fonts.Bold.title3,
                    Fonts.Bold.headline,
                    Fonts.Bold.body,
                    Fonts.Bold.callout,
                    Fonts.Bold.subheadline,
                    Fonts.Bold.footnote,
                    Fonts.Bold.caption1,
                    Fonts.Bold.caption2,
                ]
            case .regularStatic:
                [
                    Fonts.RegularStatic.largeTitle,
                    Fonts.RegularStatic.title1,
                    Fonts.RegularStatic.title2,
                    Fonts.RegularStatic.title3,
                    Fonts.RegularStatic.headline,
                    Fonts.RegularStatic.body,
                    Fonts.RegularStatic.callout,
                    Fonts.RegularStatic.subheadline,
                    Fonts.RegularStatic.footnote,
                    Fonts.RegularStatic.caption1,
                    Fonts.RegularStatic.caption2,
                ]
            case .boldStatic:
                [
                    Fonts.BoldStatic.largeTitle,
                    Fonts.BoldStatic.title1,
                    Fonts.BoldStatic.title2,
                    Fonts.BoldStatic.title3,
                    Fonts.BoldStatic.headline,
                    Fonts.BoldStatic.body,
                    Fonts.BoldStatic.callout,
                    Fonts.BoldStatic.subheadline,
                    Fonts.BoldStatic.footnote,
                    Fonts.BoldStatic.caption1,
                    Fonts.BoldStatic.caption2,
                ]
            }
        }
    }

    enum TextStyle: Int, CaseIterable {
        case largeTitle
        case title1
        case title2
        case title3
        case headline
        case body
        case callout
        case subheadline
        case footnote
        case caption1
        case caption2
    }
}
#endif
