//
//  EarnHowItWorksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct EarnHowItWorksView: View {
    // [REDACTED_TODO_COMMENT]
    static let title = "How it works"

    let content: EarnHowItWorks
    let onLearnMore: (URL) -> Void
    let onGotIt: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(indexed: content.steps, id: \.1) { index, step in
                Row(title: step.title, subtitle: step.description)
                    .titleLineLimit(nil)
                    .subtitleLineLimit(nil)
                    .showDivider(index < content.steps.count - 1)
                    .start { StepNumber(number: index + 1) }
            }
        }
        .padding(.bottom, Constants.bottomPadding)
        .footer {
            Footer(.buttons(primary: gotItButton, secondary: learnMoreButton, orientation: .horizontal))
                .caption(attribution)
        }
    }
}

// MARK: - Subviews

private extension EarnHowItWorksView {
    var attribution: AttributedString {
        var text = AttributedString(content.attribution.text)

        if let range = text.range(of: content.attribution.highlighted) {
            text[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return text
    }

    var learnMoreButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.commonLearnMore,
            accessibilityLabel: Localization.commonLearnMore,
            action: { onLearnMore(content.learnMoreURL) }
        )
        .styleType(.secondary(.default))
    }

    var gotItButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.commonGotIt,
            accessibilityLabel: Localization.commonGotIt,
            action: onGotIt
        )
        .styleType(.primary)
    }
}

// MARK: - StepNumber

private struct StepNumber: View {
    let number: Int

    @ScaledMetric private var slotSide: CGFloat = 24
    @ScaledMetric private var circleSide: CGFloat = 20

    var body: some View {
        Text("\(number)")
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textInversePrimary)
            .frame(size: CGSize(bothDimensions: circleSide))
            .background(Circle().fill(DesignSystem.Color.bgInverse))
            .frame(size: CGSize(bothDimensions: slotSide))
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension EarnHowItWorksView {
    enum Constants {
        static let bottomPadding: CGFloat = 24
    }
}

// MARK: - Previews

#Preview("Lending on Aave") {
    Color.clear.modal(isPresented: .constant(true), navigation: .title(EarnHowItWorksView.title)) {
        EarnHowItWorksView(content: .lendingOnAavePreview, onLearnMore: { _ in }, onGotIt: {})
    }
}

#Preview("High Yield Vault") {
    Color.clear.modal(isPresented: .constant(true), navigation: .title(EarnHowItWorksView.title)) {
        EarnHowItWorksView(content: .highYieldVaultPreview, onLearnMore: { _ in }, onGotIt: {})
    }
}
