//
//  OnboardingSeedPhraseIntroView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct OnboardingSeedPhraseIntroView: View {
    let readMoreAction: () -> Void
    let generateSeedAction: () -> Void
    let importWalletAction: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Assets.Onboarding.listWithPencil.image
                .foregroundColor(DesignSystem.Color.iconTertiary)

            VStack(spacing: 14) {
                Text(Localization.onboardingSeedPhraseIntroLegacy)
                    .style(
                        Fonts.Bold.caption2,
                        color: DesignSystem.Color.textAccentRed
                    )
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(DesignSystem.Color.bgAccentRedSubtle)
                    .cornerRadiusContinuous(8)

                Text(Localization.onboardingSeedIntroTitle)
                    .style(
                        Fonts.Bold.title1,
                        color: DesignSystem.Color.textPrimary
                    )
                    .multilineTextAlignment(.center)

                Text(Localization.onboardingSeedIntroMessage)
                    .style(
                        Fonts.Regular.callout,
                        color: DesignSystem.Color.textSecondary
                    )
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
            }

            SwiftUI.Button(action: readMoreAction) {
                HStack {
                    Assets.arrowRightUpMini.image
                        .renderingMode(.template)
                        .foregroundColor(DesignSystem.Color.iconPrimary)

                    Text(Localization.onboardingSeedButtonReadMore)
                        .style(
                            Fonts.Bold.subheadline,
                            color: DesignSystem.Color.textPrimary
                        )
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignSystem.Color.borderSecondary, lineWidth: 1)
                )
            }
            .padding(.top, 12)

            Spacer()

            bottomButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
    }

    @ViewBuilder
    var bottomButtons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: Localization.onboardingSeedIntroButtonGenerate,
                style: .secondary,
                action: generateSeedAction
            )

            MainButton(
                title: Localization.onboardingSeedIntroButtonImport,
                style: .secondary,
                action: importWalletAction
            )
        }
    }
}

#Preview {
    OnboardingSeedPhraseIntroView(
        readMoreAction: {},
        generateSeedAction: {},
        importWalletAction: {}
    )
}
