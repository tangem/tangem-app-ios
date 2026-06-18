//
//  TangemPaySuccessView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPaySuccessView: View {
    let model: Model
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                model.icon.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)

                VStack(alignment: .leading, spacing: 0) {
                    Text(model.title)
                        .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(model.subtitle)
                        .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .padding(.top, 64)

            Spacer()

            TangemButtonV2(
                label: AttributedString(model.buttonTitle),
                accessibilityLabel: model.buttonTitle,
                action: action
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TangemPaySuccessGlowBackground())
    }
}

extension TangemPaySuccessView {
    struct Model {
        let icon: ImageType
        let title: String
        let subtitle: String
        let buttonTitle: String
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Daily limit") {
    TangemPaySuccessView(
        model: .init(
            icon: DesignSystem.Icons.Success.regular20,
            title: "Daily limit is set",
            subtitle: "You can change it again anytime you like",
            buttonTitle: "Done"
        ),
        action: {}
    )
}

#Preview("PIN code") {
    TangemPaySuccessView(
        model: .init(
            icon: DesignSystem.Icons.Success.regular20,
            title: "Pin code set",
            subtitle: "Don't share it with anybody else",
            buttonTitle: "Close"
        ),
        action: {}
    )
}
#endif // DEBUG
