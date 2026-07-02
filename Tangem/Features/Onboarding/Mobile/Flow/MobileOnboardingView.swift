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
    @State private var isModallyPresented: Bool = false

    @ObservedObject var viewModel: MobileOnboardingViewModel

    private var configuration: StepsFlowConfiguration {
        StepsFlowConfiguration(
            hasProgressBar: viewModel.flowBuilder.hasProgressBar,
            navigationBarHeight: OnboardingLayoutConstants.navbarSize.height,
            progressBarHeight: OnboardingLayoutConstants.progressBarHeight,
            progressBarPadding: OnboardingLayoutConstants.progressBarPadding
        )
    }

    private var stepsFlowTopPadding: CGFloat {
        isModallyPresented ? .unit(.x4) : 0
    }

    var body: some View {
        ZStack {
            StepsFlowView(builder: viewModel.flowBuilder, configuration: configuration)
                .padding(.top, stepsFlowTopPadding)
                .id(viewModel.flowId)

            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)
        }
        .onModalDetection { isModallyPresented = $0 }
        .background(Color.clear.alert(item: $viewModel.alert) { $0.alert })
    }
}
