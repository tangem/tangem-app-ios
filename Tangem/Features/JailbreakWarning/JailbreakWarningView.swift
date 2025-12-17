//
//  JailbreakWarningView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct JailbreakWarningView: View {
    let viewModel: JailbreakWarningViewModel

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()

            ZStack(alignment: .center) {
                Circle()
                    .fill(Colors.Icon.warning.opacity(0.1))
                    .frame(width: 72, height: 72)

                Assets.redCircleWarning20Outline.image
                    .resizable()
                    .frame(width: 32, height: 32)
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

            MainButton(settings: viewModel.primaryButtonSettings)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
    }
}
