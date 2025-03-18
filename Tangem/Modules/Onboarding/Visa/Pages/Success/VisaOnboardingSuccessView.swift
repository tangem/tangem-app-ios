//
//  VisaOnboardingSuccessView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingSuccessView: View {
    let fireConfetti: Binding<Bool>
    let finishAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Assets.Onboarding.successCheckmark.image

            VStack(spacing: 14) {
                Text(Localization.commonSuccess)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)

                Text(Localization.visaOnboardingSuccessScreenDescription)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
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
