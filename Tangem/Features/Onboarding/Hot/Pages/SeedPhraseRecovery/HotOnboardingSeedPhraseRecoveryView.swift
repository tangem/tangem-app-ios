//
//  HotOnboardingSeedPhraseRecoveryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingSeedPhraseRecoveryView: View {
    typealias ViewModel = HotOnboardingSeedPhraseRecoveryViewModel

    let viewModel: ViewModel

    private let wordsVerticalSpacing: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    infoView(item: viewModel.infoItem)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)

                    phraseView(item: viewModel.phraseItem)
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
    }
}

// MARK: - Subviews

private extension HotOnboardingSeedPhraseRecoveryView {
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
