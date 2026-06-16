//
//  DynamicAddressesEnterView.swift
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

struct DynamicAddressesEnterView: View {
    @ObservedObject var viewModel: DynamicAddressesEnterViewModel

    var body: some View {
        NavigationStack {
            GroupedScrollView(contentType: .plain(spacing: 32)) {
                topView
                    .padding(.horizontal, 24)

                featuresSection
                    .padding(.horizontal, 24)
            }
            .interContentPadding(16)
            .overlay(alignment: .bottom) { overlayButtonView }
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $viewModel.alert) { $0.alert }
            .toolbar {
                NavigationToolbarButton
                    .close(placement: .topBarTrailing, action: viewModel.close)
            }
        }
    }

    // MARK: - Main Content

    private var topView: some View {
        VStack(spacing: 20) {
            avatarView

            descriptionSection
        }
    }

    private var avatarView: some View {
        Circle()
            .fill(Colors.Icon.accent.opacity(0.1))
            .frame(width: 72, height: 72)
            .overlay {
                Assets.dynamicAddressesRowsIcon.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Colors.Icon.accent)
            }
    }

    private var descriptionSection: some View {
        VStack(spacing: 8) {
            Text(Localization.dynamicAddresses)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)

            Text(Localization.dynamicAddressesEnterSubtitle)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            featureRow(
                icon: Assets.Glyphs.boldFlash.image,
                title: Localization.dynamicAddressesEnterFeaturesRecevingTitle,
                description: Localization.dynamicAddressesEnterFeaturesRecevingDescription
            )

            featureRow(
                icon: Assets.Glyphs.checkmarkShield.image,
                title: Localization.dynamicAddressesEnterFeaturesPrivacyTitle,
                description: Localization.dynamicAddressesEnterFeaturesPrivacyDescription
            )
        }
    }

    private func featureRow(icon: Image, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            icon
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .style(Fonts.Bold.callout, color: Colors.Icon.primary1)

                Text(description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }
        }
    }

    // MARK: - Overlay Button

    private var overlayButtonView: some View {
        MainButton(
            title: Localization.dynamicAddressesEnterMainButtonTitle,
            icon: viewModel.mainButtonIcon,
            isLoading: viewModel.mainButtonIsLoading,
            action: viewModel.userDidTapEnableAction
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
