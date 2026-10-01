//
//  TypographyShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUIUtils

struct TypographyShowcase: View {
    @State private var style: Style = .bodyMedium
    @State private var text = "Your Tangem Wallet keeps private keys on the card chip, so every transaction needs a tap of the card to be signed."

    var body: some View {
        DSShowcase("Typography") { controls in
            controls.picker("Token", $style, options: Style.allCases, label: \.name)
            controls.text("Text", $text)
            controls.readout("Metrics", style.metrics)
        } stage: {
            VStack(alignment: .leading, spacing: 16) {
                Text(text)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Bitcoin · 0.04817 BTC")
                    Text("Ethereum · 1.2034 ETH")
                    Text("Tether USD · 2,450.00 USDT")
                }
            }
            .style(style.token, color: DesignSystem.Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Color.borderPrimary, lineWidth: 1)
            )
        } matrix: {
            DSShowcaseMatrix(rows: Style.allCases, rowLabel: { $0.name }) { style in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total balance $69,786.00")
                        .style(style.token, color: DesignSystem.Color.textPrimary)

                    Text(style.metrics)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                }
            }
        }
    }
}

private extension TypographyShowcase {
    enum Style: CaseIterable {
        case displayMedium
        case headingMedium
        case headingSmall
        case subheadingMedium
        case bodyMedium
        case captionMedium

        var name: String {
            switch self {
            case .displayMedium: "display / medium"
            case .headingMedium: "heading / medium"
            case .headingSmall: "heading / small"
            case .subheadingMedium: "subheading / medium"
            case .bodyMedium: "body / medium"
            case .captionMedium: "caption / medium"
            }
        }

        var token: TangemTypographyToken {
            switch self {
            case .displayMedium: DesignSystem.Font.displayMediumToken
            case .headingMedium: DesignSystem.Font.headingMediumToken
            case .headingSmall: DesignSystem.Font.headingSmallToken
            case .subheadingMedium: DesignSystem.Font.subheadingMediumToken
            case .bodyMedium: DesignSystem.Font.bodyMediumToken
            case .captionMedium: DesignSystem.Font.captionMediumToken
            }
        }

        var metrics: String {
            "\(Self.format(token.fontSize)) / \(Self.format(token.lineHeight)) · tracking \(Self.format(token.tracking))"
        }

        private static func format(_ value: CGFloat) -> String {
            String(format: "%g", Double(value))
        }
    }
}
#endif
