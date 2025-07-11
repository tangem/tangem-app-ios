//
//  HotOnboardingSuccessView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingSuccessView: View {
    typealias ViewModel = HotOnboardingSuccessViewModel

    let viewModel: ViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            infoView(viewModel.infoItem)
            Spacer()
            continueButton(viewModel.continueItem)
        }
        .onAppear(perform: viewModel.onAppear)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Subviews

extension HotOnboardingSuccessView {
    func infoView(_ item: ViewModel.InfoItem) -> some View {
        VStack(spacing: 20) {
            item.icon.image

            VStack(spacing: 12) {
                Text(item.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)

                Text(item.description)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    func continueButton(_ item: ViewModel.ContinueItem) -> some View {
        MainButton(
            title: item.title,
            action: item.action
        )
    }
}
