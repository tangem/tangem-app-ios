//
//  WelcomeOnboardingTOSView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeOnboardingTOSView: View {
    @ObservedObject var viewModel: WelcomeOnboardingTOSViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            TOSView(viewModel: .init())

            MainButton(
                title: Localization.commonAccept,
                action: viewModel.didTapAccept
            )
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    WelcomeOnboardingTOSView(viewModel: .init(delegate: WelcomeOnboardingTOSDelegateStub()))
}
