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
    @ObservedObject
    var viewModel: YieldAvailableNotificationViewModel

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
                Text(viewModel.state.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationTitle)
                    .skeletonable(isShown: viewModel.state.isLoading)

                Text(viewModel.state.description)
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
        viewModel.state.icon
            .resizable()
            .frame(size: .init(bothDimensions: 36))
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.yieldModuleNotificationIcon)
    }
}
