//
//  PushNotificationsWarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct PushNotificationsWarningView: View {
    @ObservedObject var viewModel: PushNotificationsWarningViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            content

            footer
        }
        .background(Colors.Background.primary)
        .onAppear(perform: viewModel.onViewAppear)
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Subviews

private extension PushNotificationsWarningView {
    var header: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }

    var content: some View {
        VStack(spacing: .zero) {
            ZStack {
                Circle()
                    .fill(Colors.Icon.attention.opacity(0.1))
                    .frame(width: 56, height: 56)

                Assets.attention.image
                    .resizable()
                    .renderingMode(.original)
                    .frame(width: 32, height: 32)
            }

            Text(Localization.pushNotificationWarningSheetTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)

            Text(Localization.pushNotificationWarningSheetDescription)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }

    var footer: some View {
        VStack(spacing: 8) {
            MainButton(
                title: Localization.commonSkip,
                style: .secondary,
                action: viewModel.onSkipTap
            )

            MainButton(
                title: Localization.pushNotificationWarningSheetButtonEnable,
                isLoading: viewModel.isRequestingPermission,
                action: viewModel.onEnableTap
            )
        }
        .padding(16)
    }
}

// MARK: - Previews

#Preview {
    PushNotificationsWarningView(
        viewModel: PushNotificationsWarningViewModel(
            permissionManager: PushNotificationsPermissionManagerStub(),
            analyticsContext: PushNotificationsWarningAnalyticsContext(zone: .onboarding, variant: .control, walletId: nil),
            dismissAction: {}
        )
    )
}
