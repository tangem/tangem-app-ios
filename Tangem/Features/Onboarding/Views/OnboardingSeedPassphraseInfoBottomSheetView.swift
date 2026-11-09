//
//  OnboardingSeedPassphraseInfoBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct OnboardingSeedPassphraseInfoBottomSheetModel: Identifiable {
    let id = UUID()
    let actionHandler: () -> Void
}

struct OnboardingSeedPassphraseInfoBottomSheetView: View {
    let model: OnboardingSeedPassphraseInfoBottomSheetModel

    var body: some View {
        VStack(spacing: 56) {
            VStack(spacing: 30) {
                Assets.infoCircle36.image
                    .foregroundStyle(DesignSystem.Color.iconAccentBlue)
                    .padding(.top, 50)

                VStack(spacing: 10) {
                    Text(Localization.commonPassphrase)
                        .style(Fonts.Regular.title1, color: DesignSystem.Color.textPrimary)

                    Text(Localization.onboardingBottomSheetPassphraseDescription)
                        .multilineTextAlignment(.center)
                        .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
                }
                .padding(.horizontal, 34)
            }

            MainButton(title: Localization.commonOk) {
                model.actionHandler()
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 6)
    }
}
