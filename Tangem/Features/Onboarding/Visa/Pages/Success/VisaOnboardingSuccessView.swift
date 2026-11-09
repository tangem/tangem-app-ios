//
//  VisaOnboardingSuccessView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct VisaOnboardingSuccessView: View {
    let fireConfetti: Binding<Bool>
    let finishAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Assets.Onboarding.successCheckmark.image

            VStack(spacing: 14) {
                Text(Localization.commonSuccess)
                    .style(Fonts.Bold.title1, color: DesignSystem.Color.textPrimary)

                Text(Localization.visaOnboardingSuccessScreenDescription)
                    .style(Fonts.Regular.callout, color: DesignSystem.Color.textSecondary)
            }

            Spacer()

            MainButton(title: Localization.commonFinish, action: finishAction)
        }
        .padding(EdgeInsets(top: 120, leading: 16, bottom: 10, trailing: 16))
        .onAppear(perform: {
            fireConfetti.wrappedValue = true
        })
    }
}

#Preview {
    VisaOnboardingSuccessView(fireConfetti: .constant(false), finishAction: {})
}
