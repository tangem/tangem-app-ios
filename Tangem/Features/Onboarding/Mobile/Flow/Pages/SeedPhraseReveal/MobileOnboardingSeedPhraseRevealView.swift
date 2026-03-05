//
//  MobileOnboardingSeedPhraseRevealView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileOnboardingSeedPhraseRevealView: View {
    typealias ViewModel = MobileOnboardingSeedPhraseRevealViewModel

    @ObservedObject var viewModel: ViewModel

    private let wordsVerticalSpacing: CGFloat = 18

    var body: some View {
        content
            .stepsFlowNavBar(title: viewModel.navigationTitle)
            .stepsFlowNavBar(leading: {
                MobileOnboardingFlowNavBarAction.close(handler: viewModel.onCloseTap).view()
            })
            .screenCaptureProtection()
            .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Subviews

private extension MobileOnboardingSeedPhraseRevealView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .item(let item):
            state(item: item)
        case .none:
            Color.clear
        }
    }

    func state(item: ViewModel.StateItem) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                infoView(item: item.info)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                phraseView(item: item.phrase)
                    .padding(.horizontal, 36)
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 16)
    }

    func infoView(item: ViewModel.InfoItem) -> some View {
        VStack(spacing: 12) {
            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(item.description)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    func phraseView(item: ViewModel.PhraseItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            WordsCaptureProtectionView(
                words: item.words,
                indexRange: item.firstRange,
                verticalSpacing: wordsVerticalSpacing
            )

            WordsCaptureProtectionView(
                words: item.words,
                indexRange: item.secondRange,
                verticalSpacing: wordsVerticalSpacing
            )
        }
    }
}
