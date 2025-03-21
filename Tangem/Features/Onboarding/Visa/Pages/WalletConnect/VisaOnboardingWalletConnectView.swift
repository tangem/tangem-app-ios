//
//  VisaOnboardingWalletConnectView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaOnboardingWalletConnectView: View {
    @ObservedObject var viewModel: VisaOnboardingWalletConnectViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Assets.Onboarding.tangemPayWc.image

            VStack(spacing: 12) {
                Text(Localization.visaOnboardingWalletConnectTitle)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(Localization.visaOnboardingWalletConnectDescription)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
            .padding(.horizontal, 36)

            Spacer()

            VStack(spacing: 10) {
                MainButton(title: Localization.commonOpenInBrowser, action: viewModel.openBrowser)

                MainButton(title: Localization.commonShareLink, style: .secondary, action: viewModel.openShareSheet)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }
}

#Preview {
    VisaOnboardingWalletConnectView(viewModel: .init())
}
