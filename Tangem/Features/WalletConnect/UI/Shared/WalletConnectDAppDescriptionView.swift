//
//  WalletConnectDAppDescriptionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectDAppDescriptionView: View {
    let viewModel: WalletConnectDAppDescriptionViewModel
    let kingfisherImageCache: ImageCache
    var verifiedDomainTapAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            iconView

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    nameView
                    verifiedDomainIcon
                    Spacer(minLength: .zero)
                }

                domainView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.linear(duration: 0.2), value: viewModel)
    }

    // MARK: - Icon

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            switch viewModel {
            case .content(let contentState) where contentState.iconURL == nil:
                fallbackIconAsset
                    .transition(.opacity)

            case .content(let contentState):
                remoteIcon(contentState)
                    .transition(.opacity)

            case .loading:
                SkeletonView()
                    .frame(width: Layout.height, height: Layout.height)
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.iconCornerRadius))
    }

    private var fallbackIconAsset: some View {
        Assets.Glyphs.explore.image
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .foregroundStyle(Colors.Icon.accent)
            .frame(width: Layout.height, height: Layout.height)
            .background(Colors.Icon.accent.opacity(0.1))
    }

    private func remoteIcon(_ contentState: WalletConnectDAppDescriptionViewModel.ContentState) -> some View {
        KFImage(contentState.iconURL)
            .targetCache(kingfisherImageCache)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: Layout.height, height: Layout.height)
    }

    // MARK: - Name

    @ViewBuilder
    private var nameView: some View {
        switch viewModel {
        case .content(let contentState):
            Text(contentState.name)
                .lineLimit(2)
                .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)
                .transition(.opacity)

        case .loading:
            SkeletonView()
                .frame(width: 120, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: Layout.textCornerRadius))
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var verifiedDomainIcon: some View {
        if case .content(let contentState) = viewModel,
           let verifiedDomainIconAsset = contentState.verifiedDomainIconAsset,
           let verifiedDomainTapAction {
            Button(action: verifiedDomainTapAction) {
                verifiedDomainIconAsset.image
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Colors.Icon.accent)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .transition(.opacity)
        }
    }

    // MARK: - DApp domain

    @ViewBuilder
    private var domainView: some View {
        switch viewModel {
        case .content(let contentState):
            Text(contentState.domain)
                .lineLimit(1)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .transition(.opacity)

        case .loading:
            SkeletonView()
                .frame(width: 168, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: Layout.textCornerRadius))
                .transition(.opacity)
        }
    }
}

extension WalletConnectDAppDescriptionView {
    enum Layout {
        /// 56
        static let height: CGFloat = 56
        /// 16
        static let iconCornerRadius: CGFloat = 16
        /// 8
        static let textCornerRadius: CGFloat = 8
    }
}
