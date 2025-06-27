//
//  WalletConnectDAppConnectionRequestView.swift
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

struct WalletConnectDAppConnectionRequestView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionRequestViewModel
    let kingfisherImageCache: ImageCache

    var body: some View {
        VStack(spacing: 14) {
            dAppAndConnectionRequestSections
            dAppVerificationWarningSection
            walletAndNetworksSections
        }
        .padding(.horizontal, 16)
        .transformEffect(.identity)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var dAppAndConnectionRequestSections: some View {
        VStack(spacing: .zero) {
            WalletConnectDAppDescriptionView(
                viewModel: viewModel.state.dAppDescriptionSection,
                kingfisherImageCache: kingfisherImageCache,
                verifiedDomainTapAction: { viewModel.handle(viewEvent: .verifiedDomainIconTapped) }
            )
            .padding(.vertical, 16)
            .padding(.horizontal, 14)

            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)

            WalletConnectDAppConnectionRequestView.ConnectionRequestSection(
                viewModel: viewModel.state.connectionRequestSection,
                tapAction: { viewModel.handle(viewEvent: .connectionRequestSectionHeaderTapped) }
            )
            .compositingGroup()
            .padding(.horizontal, 14)
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var dAppVerificationWarningSection: some View {
        if let dAppVerificationWarningSection = viewModel.state.dAppVerificationWarningSection {
            WalletConnectWarningNotificationView(viewModel: dAppVerificationWarningSection)
        }
    }

    private var walletAndNetworksSections: some View {
        VStack(spacing: .zero) {
            walletSection
                .padding(.horizontal, 14)

            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)
                .padding(.leading, 46)
                .padding(.trailing, 14)

            WalletConnectDAppConnectionRequestView.NetworksSection(
                viewModel: viewModel.state.networksSection,
                tapAction: { viewModel.handle(viewEvent: .networksRowTapped) }
            )
            .padding(.horizontal, 14)

            if let networksWarningSection = viewModel.state.networksWarningSection {
                Divider()
                    .frame(height: 1)
                    .overlay(Colors.Stroke.primary)

                WalletConnectWarningNotificationView(viewModel: networksWarningSection)
            }
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var walletSection: some View {
        Button(action: { viewModel.handle(viewEvent: .walletRowTapped) }) {
            HStack(spacing: .zero) {
                viewModel.state.walletSection.iconAsset.image
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Colors.Icon.accent)

                Spacer()
                    .frame(width: 8)

                Text(viewModel.state.walletSection.label)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                Spacer(minLength: .zero)

                Text(viewModel.state.walletSection.selectedUserWalletName)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                    .padding(.horizontal, 4)

                viewModel.state.walletSection.trailingIconAsset?.image
                    .resizable()
                    .frame(width: 18, height: 24)
                    .foregroundStyle(Colors.Icon.informative)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
