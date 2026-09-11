//
//  ForYouAccountSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct ForYouAccountSelectorView: View {
    @ObservedObject var viewModel: ForYouAccountSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(viewModel.sections, content: sectionView)
                }
                .padding([.horizontal, .top], 16)
            }
            applyFooter
        }
    }
}

private extension ForYouAccountSelectorView {
    func sectionView(_ section: ForYouAccountSelectorSection) -> some View {
        VStack(spacing: 0) {
            walletHeader(section)

            ForEach(section.accounts) { item in
                AccountRowButtonView(viewModel: item.rowViewModel) {
                    TangemUI.Checkmark(checked: viewModel.isAccountSelected(item.id)) {}
                        .allowsHitTesting(false)
                }
                .buttonStyle(.plain)
                .lineLimit(1)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
        .background(Colors.Background.action)
        .cornerRadius(24, corners: .allCorners)
    }

    func walletHeader(_ section: ForYouAccountSelectorSection) -> some View {
        HStack(spacing: 8) {
            Text(section.walletName)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            section.walletThumbnailType.map { type in
                MiniatureWalletView(type: type)
                    .frame(size: CGSize(bothDimensions: 24))
            }

            Spacer(minLength: 8)

            TangemUI.Checkmark(checked: viewModel.isWalletFullySelected(section)) {
                viewModel.toggleWallet(section)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    var applyFooter: some View {
        MainButton(
            title: Localization.commonApply,
            style: .secondary,
            isDisabled: !viewModel.canApply,
            action: viewModel.apply
        )
        .padding(16)
    }
}
