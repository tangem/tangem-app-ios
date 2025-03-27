//
//  VisaOnboardingInProgressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct VisaOnboardingInProgressView: View {
    @ObservedObject var viewModel: VisaOnboardingInProgressViewModel

    var body: some View {
        VStack(spacing: 26) {
            Assets.Onboarding.inProgress64.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
                .padding(.top, 126)

            VStack(spacing: 14) {
                Text(viewModel.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                Text(viewModel.description)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 54)

            Spacer()
        }
        .padding(.bottom, 10)
    }
}
