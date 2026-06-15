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
            VStack(alignment: .leading, spacing: DesignSystem.Tokens.Spacing.s200) {
                model.icon.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: DesignSystem.Tokens.Size.s350, height: DesignSystem.Tokens.Size.s350)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Icon.primary)

                VStack(alignment: .leading, spacing: 0) {
                    Text(model.title)
                        .style(DesignSystem.Tokens.Font.Heading.medium, color: DesignSystem.Tokens.Theme.Text.primary)

                    Text(model.subtitle)
                        .style(DesignSystem.Tokens.Font.Heading.medium, color: DesignSystem.Tokens.Theme.Text.secondary)
                }
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Tokens.Spacing.s300)
            .padding(.top, DesignSystem.Tokens.Spacing.s800)

            Spacer()

            TangemButtonV2(
                label: AttributedString(model.buttonTitle),
                accessibilityLabel: model.buttonTitle,
                action: action
            )
            .size(.x12)
            .styleType(.default)
            .horizontalLayout(.infinity)
            .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)
            .padding(.bottom, DesignSystem.Tokens.Spacing.s150)
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
