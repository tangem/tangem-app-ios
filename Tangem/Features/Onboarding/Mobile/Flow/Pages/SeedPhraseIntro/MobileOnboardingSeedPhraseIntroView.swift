//
//  MobileOnboardingSeedPhraseIntroView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileOnboardingSeedPhraseIntroView: View {
    typealias ViewModel = MobileOnboardingSeedPhraseIntroViewModel

    let viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .onAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension MobileOnboardingSeedPhraseIntroView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                commonView(item: viewModel.commonItem)
                    .padding(.horizontal, 24)

                ForEach(viewModel.infoItems) {
                    infoView(item: $0)
                        .padding(.leading, 32)
                        .padding(.trailing, 26)
                }
            }
            .padding(.top, 32)
        }
        .safeAreaInset(edge: .bottom, spacing: 16) {
            actionButtons
                .bottomPaddingIfZeroSafeArea()
        }
    }

    var actionButtons: some View {
        MainButton(
            title: viewModel.continueButtonTitle,
            action: viewModel.onContinueTap
        )
    }

    func commonView(item: ViewModel.CommonItem) -> some View {
        VStack(spacing: 12) {
            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)

            Text(item.subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.center)
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
