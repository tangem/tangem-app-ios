//
//  HotOnboardingSeedPhraseIntroView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct HotOnboardingSeedPhraseIntroView: View {
    typealias ViewModel = HotOnboardingSeedPhraseIntroViewModel

    let viewModel: ViewModel

    var body: some View {
        VStack(spacing: 32) {
            commonView(item: viewModel.commonItem)
                .padding(.horizontal, 24)

            ForEach(viewModel.infoItems) {
                infoView(item: $0)
                    .padding(.leading, 32)
                    .padding(.trailing, 26)
            }

            Spacer()

            MainButton(
                title: viewModel.continueButtonTitle,
                action: viewModel.onContinueTap
            )
        }
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Subviews

private extension HotOnboardingSeedPhraseIntroView {
    func commonView(item: ViewModel.CommonItem) -> some View {
        VStack(spacing: 12) {
            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(item.subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func infoView(item: ViewModel.InfoItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Colors.Control.unchecked)
                    .frame(width: 42)

                item.icon.image
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .style(Fonts.Bold.callout, color: Colors.Icon.primary1)

                Text(item.description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
