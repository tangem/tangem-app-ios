//
//  GachaWelcomeView+Footer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

private typealias Footer = GachaWelcomeView.Footer

extension GachaWelcomeView {
    struct Footer: View {
        let onCreateAccountTap: () -> Void

        var body: some View {
            VStack(spacing: 12) {
                Text(Self.legalTermsText)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)

                createAccountButton
            }
            .padding(.horizontal, 16)
            .padding(.top, Metrics.topPadding)
            .padding(.bottom, 12)
            .background { background.ignoresSafeArea(edges: .bottom) }
        }
    }
}

// MARK: - Footer + Content

private extension Footer {
    var createAccountButton: some View {
        // [REDACTED_TODO_COMMENT]
        TangemUI.Button(label: "Create Gacha account", accessibilityLabel: nil, action: onCreateAccountTap)
            .iconEnd(DesignSystem.Icons.LogoTangem.regular24)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .size(.x12)
    }

    var background: some View {
        DesignSystem.Color.bgPrimary
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, DesignSystem.Color.bgPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Metrics.fadeHeight)
                .alignmentGuide(.top) { $0[.bottom] }
            }
    }

    // [REDACTED_TODO_COMMENT]
    static let legalTermsText: AttributedString = {
        let collectorCryptTerms = "Collector Crypt T&Cs"
        let tangemTerms = "Tangem T&Cs"

        var text = AttributedString("By creating a Gacha account you agree with \(collectorCryptTerms) and \(tangemTerms)")

        for terms in [collectorCryptTerms, tangemTerms] {
            if let range = text.range(of: terms) {
                text[range].foregroundColor = DesignSystem.Color.textPrimary
            }
        }

        return text
    }()
}

// MARK: - Metrics

private extension Footer {
    enum Metrics {
        static let topPadding: CGFloat = 8
        static let fadeHeight: CGFloat = 56
    }
}

// MARK: - Previews

#Preview {
    ZStack(alignment: .bottom) {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        Footer(onCreateAccountTap: {})
    }
}
