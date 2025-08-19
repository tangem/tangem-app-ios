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

    var body: some View {
        ZStack {
            ConfettiView(shouldFireConfetti: $viewModel.shouldFireConfetti)
                .allowsHitTesting(false)

            MobileOnboardingFlowView(builder: viewModel.flowBuilder)
        }
        .background(Color.clear.alert(item: $viewModel.alert) { $0.alert })
    }
}
