//
//  YieldAvailableNotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct YieldAvailableNotificationView: View {
    @StateObject
    private var viewModel: YieldAvailableNotificationViewModel

    // MARK: - Init

    init(viewModel: YieldAvailableNotificationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - View Body

    var body: some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
            .task {
                await viewModel.fetchAvailability()
            }
    }

    // MARK: - Sub Views

    var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            messageIconContent
            button
        }
    }

    @ViewBuilder
    private var button: some View {
        switch viewModel.state {
        case .available, .loading:
            MainButton(
                title: Localization.commonGetStarted,
                style: .secondary,
                size: .notification,
                isLoading: viewModel.state.isLoading,
                action: { viewModel.onGetStartedTap() }
            )
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationButton)

        case .unavailable:
            EmptyView()
        }
    }

    private var messageIconContent: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(getTitle())
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationTitle)
                    .skeletonable(isShown: viewModel.state.isLoading)

                Text(getDescription())
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .infinityFrame(axis: .horizontal, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationMessage)
                    .skeletonable(isShown: viewModel.state.isLoading)
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.trailing, 20)
    }

    private var icon: some View {
        getIcon()
            .resizable()
            .frame(size: .init(bothDimensions: 36))
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationIcon)
    }

    // MARK: - Private Implementation

    private func getTitle() -> String {
        switch viewModel.state {
        case .available(let apy):
            return Localization.yieldModuleTokenDetailsEarnNotificationTitle(apy)
        case .loading:
            return Localization.yieldModuleTokenDetailsEarnNotificationTitle("0.0%")
        case .unavailable:
            return "Earnings unavailable"
        }
    }

    private func getDescription() -> String {
        switch viewModel.state {
        case .available, .loading:
            return Localization.yieldModuleTokenDetailsEarnNotificationDescription
        case .unavailable:
            return "The interest service isn’t available at the moment. Please try again later."
        }
    }

    private func getIcon() -> Image {
        switch viewModel.state {
        case .unavailable, .loading:
            return Assets.YieldModule.yieldModuleLogoGray.image
        case .available:
            return Assets.YieldModule.yieldModuleLogo.image
        }
    }
}
