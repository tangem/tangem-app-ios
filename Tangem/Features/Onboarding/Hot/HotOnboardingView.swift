//
//  HotOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingView: View {
    @ObservedObject var viewModel: HotOnboardingViewModel

    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)

            HotOnboardingFlowView(builder: viewModel.flowBuilder)
        }
    }
}
