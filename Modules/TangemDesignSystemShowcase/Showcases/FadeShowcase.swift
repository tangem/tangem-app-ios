//
//  FadeShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct FadeShowcase: View {
    @State private var variant: Fade.Variant = .soft
    @State private var position: Fade.Position = .bottom
    @State private var fadeColor: FadeColor = .primary
    @State private var height: CGFloat = 96
    @State private var isBlurEnabled = false

    var body: some View {
        DSShowcase("Fade") { controls in
            controls.picker("Variant", $variant)
            controls.picker("Position", $position)
            controls.picker("Fade color", $fadeColor)
            controls.value("Height", $height, in: 56 ... 240, step: 1)
            controls.toggle("Blur", $isBlurEnabled)
            controls.note("Match Environment → Background to the fade color to see it blend into the surface.")
        } stage: {
            tokenList
                .frame(height: 280, alignment: .top)
                .overlay(alignment: position.alignment) {
                    Fade(position: position)
                        .variant(variant)
                        .blurred(isBlurEnabled)
                        .backgroundColor(fadeColor.color)
                        .frame(height: height)
                }
                .clipped()
        } matrix: {
            DSShowcaseMatrix(rows: Fade.Variant.allCases, columns: Fade.Position.allCases) { variant, position in
                tokenList
                    .frame(width: 160, height: 120, alignment: position == .top ? .bottom : .top)
                    .overlay(alignment: position.alignment) {
                        Fade(position: position)
                            .variant(variant)
                            .frame(height: 96)
                    }
                    .clipped()
            }
        }
    }

    private var tokenList: some View {
        VStack(spacing: 0) {
            ForEach(Self.tokens, id: \.name) { token in
                HStack(spacing: 12) {
                    Text(token.name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(token.balance)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 12)
            }
        }
    }

    private static var tokens: [Token] {
        [
            Token(name: "Bitcoin", balance: "0.4821 BTC"),
            Token(name: "Ethereum", balance: "3.1947 ETH"),
            Token(name: "Tether", balance: "1,250.00 USDT"),
            Token(name: "Solana", balance: "42.18 SOL"),
            Token(name: "Polygon", balance: "815.40 POL"),
            Token(name: "Cardano", balance: "2,300.00 ADA"),
            Token(name: "Toncoin", balance: "96.72 TON"),
        ]
    }
}

private extension FadeShowcase {
    struct Token {
        let name: String
        let balance: String
    }

    enum FadeColor: CaseIterable {
        case primary
        case secondary
        case inverse

        var color: Color {
            switch self {
            case .primary: DesignSystem.Color.bgPrimary
            case .secondary: DesignSystem.Color.bgSecondary
            case .inverse: DesignSystem.Color.bgInverse
            }
        }
    }
}

private extension Fade.Position {
    var alignment: Alignment {
        switch self {
        case .top: .top
        case .bottom: .bottom
        }
    }
}
#endif
