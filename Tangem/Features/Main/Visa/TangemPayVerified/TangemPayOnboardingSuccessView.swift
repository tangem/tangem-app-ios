//
//  TangemPayOnboardingSuccessView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayOnboardingSuccessView: View {
    @ObservedObject var viewModel: TangemPayOnboardingSuccessViewModel

    var body: some View {
        StatusScreen(
            title: Localization.tangempayOnboardingSuccessTitle,
            description: Localization.tangempayOnboardingSuccessDescription,
            actionTitle: Localization.commonNext,
            action: viewModel.close
        )
        .appearance(.info)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
    }
}
