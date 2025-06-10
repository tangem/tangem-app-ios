//
//  VisaOnboardingInProgressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import Lottie

struct VisaOnboardingInProgressView: View {
    @ObservedObject var viewModel: VisaOnboardingInProgressViewModel

    var body: some View {
        VStack(spacing: 26) {
            LottieView(animation: LottieFile.visaOnboardingInProgress)
                .playing(loopMode: .loop)
                .backgroundBehavior(.pauseAndRestore)
                .frame(size: .init(bothDimensions: 64))
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
