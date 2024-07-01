//
//  OnboardingPushNotificationsView.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingPushNotificationsView: View {
    @ObservedObject var viewModel: OnboardingPushNotificationsViewModel

    let buttonsAxis: Axis

    var body: some View {
        VStack(spacing: 0.0) {
            Spacer()

            Group {
                VStack(spacing: 0.0) {
                    Assets.notificationBell.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.onboarding)

                    FixedSpacer(height: 28.0)

                    Text(Localization.userPushNotificationAgreementHeader)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    FixedSpacer(height: 44.0)
                }

                VStack(spacing: 0.0) {
                    OnboardingFeatureDescriptionView(
                        icon: Assets.notificationBulletItemOne,
                        description: Localization.userPushNotificationAgreementArgumentOne
                    )

                    FixedSpacer(height: 28.0)

                    OnboardingFeatureDescriptionView(
                        icon: Assets.notificationBulletItemTwo,
                        description: Localization.userPushNotificationAgreementArgumentTwo
                    )
                }
            }
            .padding(.horizontal, 20.0)

            Spacer()

            buttonsContainer
        }
    }

    @ViewBuilder
    private var buttonsContainer: some View {
        Group {
            switch buttonsAxis {
            case .horizontal:
                HStack(spacing: 10.0) { buttons }
            case .vertical:
                VStack(spacing: 8.0) { buttons }
            }
        }
        .padding(.vertical, 14.0)
        .padding(.horizontal, 16.0)
    }

    @ViewBuilder
    private var buttons: some View {
        MainButton(
            title: viewModel.allowButtonTitle,
            action: viewModel.didTapAllow
        )

        MainButton(
            title: viewModel.laterButtonTitle,
            style: .secondary,
            action: viewModel.didTapLater
        )
    }
}

// MARK: - Previews

#Preview {
    let permissionManager = PushNotificationsInteractorTrampoline(
        isAvailable: { true },
        canPostponePermissionRequest: { true },
        allowRequest: {},
        postponeRequest: {}
    )
    let viewModel = OnboardingPushNotificationsViewModel(
        permissionManager: permissionManager,
        delegate: OnboardingPushNotificationsDelegateStub()
    )

    return VStack {
        OnboardingPushNotificationsView(viewModel: viewModel, buttonsAxis: .vertical)

        Spacer()

        OnboardingPushNotificationsView(viewModel: viewModel, buttonsAxis: .horizontal)
    }
}
