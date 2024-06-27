//
//  OnboardingPushNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingPushNotificationsView: View {
    @ObservedObject var viewModel: OnboardingPushNotificationsViewModel

    var body: some View {
        VStack {
            Spacer()

            // [REDACTED_TODO_COMMENT]
            Text("PUSH NOTIFICATIONS CONTENT")

            Spacer()

            buttons
        }
    }

    private var buttons: some View {
        VStack {
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
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    OnboardingPushNotificationsView(viewModel: .init(canPostpone: false, delegate: OnboardingPushNotificationsDelegateStub()))
}
