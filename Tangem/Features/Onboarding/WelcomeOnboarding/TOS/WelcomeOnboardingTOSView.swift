//
//  WelcomeOnboardingTOSView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct WelcomeOnboardingTOSView: View {
    @ObservedObject var viewModel: WelcomeOnboardingTOSViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            TOSView(viewModel: .init())

            MainButton(
                title: Localization.commonAccept,
                action: viewModel.didTapAccept
            )
            .accessibilityIdentifier(AccessibilityIdentifiers.TOS.acceptButton)
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .safeAreaInset(edge: .top) {
            NavigationBar(
                title: Localization.disclaimerTitle,
                settings: .init(
                    backgroundColor: Color.clear,
                    height: 30
                )
            )
        }
    }
}

#Preview {
    WelcomeOnboardingTOSView(viewModel: .init(delegate: WelcomeOnboardingTOSDelegateStub()))
}
