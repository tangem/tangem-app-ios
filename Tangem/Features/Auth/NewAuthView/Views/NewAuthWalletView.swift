//
//  NewAuthWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemAssets
import TangemUI

struct NewAuthWalletView: View {
    @StateObject private var viewModel: NewAuthWalletViewModel

    init(item: NewAuthViewModel.WalletItem) {
        _viewModel = StateObject(wrappedValue: NewAuthWalletViewModel(item: item))
    }

    var body: some View {
        Button(action: viewModel.onTap) {
            HStack(spacing: 12) {
                icon
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Colors.Field.primary)
            .cornerRadius(14, corners: .allCorners)
        }
    }
}

// MARK: - Subviews

private extension NewAuthWalletView {
    var icon: some View {
        image
            .frame(width: 36, height: 36)
            .skeletonable(
                isShown: viewModel.icon.isLoading,
                size: CGSize(width: 36, height: 22),
                paddings: EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
            )
    }

    @ViewBuilder
    var image: some View {
        switch viewModel.icon {
        case .loading:
            Color.clear

        case .loaded(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .failedToLoad:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    var info: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Text(viewModel.description)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                if viewModel.isProtected {
                    Assets.stakingLockIcon.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}
