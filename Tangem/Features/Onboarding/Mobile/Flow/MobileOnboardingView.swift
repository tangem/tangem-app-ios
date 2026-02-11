//
//  MobileOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileOnboardingView: View {
    @ObservedObject var viewModel: MobileOnboardingViewModel

    private var configuration: StepsFlowConfiguration {
        StepsFlowConfiguration(
            hasProgressBar: viewModel.flowBuilder.hasProgressBar,
            navigationBarHeight: OnboardingLayoutConstants.navbarSize.height,
            progressBarHeight: OnboardingLayoutConstants.progressBarHeight,
            progressBarPadding: OnboardingLayoutConstants.progressBarPadding
        )
    }

    var body: some View {
        ZStack {
            StepsFlowView(builder: viewModel.flowBuilder, configuration: configuration)

            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
        }
        .background(Color.clear.alert(item: $viewModel.alert) { $0.alert })
    }
}
