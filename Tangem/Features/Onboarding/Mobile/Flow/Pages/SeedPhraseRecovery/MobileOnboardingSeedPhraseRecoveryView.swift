//
//  MobileOnboardingSeedPhraseRecoveryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileOnboardingSeedPhraseRecoveryView: View {
    typealias ViewModel = MobileOnboardingSeedPhraseRecoveryViewModel

    @ObservedObject var viewModel: ViewModel

    private let wordsVerticalSpacing: CGFloat = 18

    var body: some View {
        switch viewModel.state {
        case .item(let item):
            state(item: item)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Subviews

private extension MobileOnboardingSeedPhraseRecoveryView {
    func state(item: ViewModel.StateItem) -> some View {
        VStack(spacing: 0) {
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

            Spacer()

            VStack(spacing: 16) {
                Text(viewModel.responsibilityDescription)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)

                MainButton(
                    title: viewModel.continueButtonTitle,
                    action: viewModel.onContinueTap
                )
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .screenCaptureProtection()
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
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
