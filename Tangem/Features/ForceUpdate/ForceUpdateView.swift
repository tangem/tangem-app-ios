//
//  ForceUpdateView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct ForceUpdateView: View {
    let viewModel: ForceUpdateViewModel

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()

            ZStack(alignment: .center) {
                Circle()
                    .fill(Colors.Icon.warning.opacity(0.1))
                    .frame(size: .init(bothDimensions: 72))

                Assets.redCircleWarning20Outline.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 32))
            }
            .padding(20)

            Text(viewModel.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .minimumScaleFactor(0.4)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text(viewModel.subtitle)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 48)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 10) {
                if let primaryButtonSettings = viewModel.primaryButtonSettings {
                    MainButton(settings: primaryButtonSettings)
                }

                if let supportButtonSettings = viewModel.supportButtonSettings {
                    MainButton(settings: supportButtonSettings)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
