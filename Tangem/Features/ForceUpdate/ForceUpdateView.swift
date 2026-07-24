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
        content
            .padding(.horizontal, 24)
            .padding(.top, 84)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .safeAreaInset(edge: .bottom) {
                buttons
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .background(ForceUpdateGlowBackground(color: viewModel.accentColor))
            .onAppear(perform: viewModel.onAppear)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            viewModel.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(size: .init(bothDimensions: 28))
                .foregroundStyle(viewModel.accentColor)
                .padding(.bottom, 16)

            Text(viewModel.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.subtitle)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            if let secondaryButton = viewModel.secondaryButton {
                button(secondaryButton)
            }

            if let primaryButton = viewModel.primaryButton {
                button(primaryButton)
            }
        }
    }

    private func button(_ model: ForceUpdateViewModel.ButtonModel) -> some View {
        TangemButtonV2(
            label: AttributedString(model.title),
            accessibilityLabel: model.title,
            action: model.action
        )
        .styleType(model.style)
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Previews

#Preview("Requires app update") {
    ForceUpdateView(viewModel: ForceUpdateViewModel(reason: .requiresAppUpdate, coordinator: nil))
}

#Preview("Requires OS update") {
    ForceUpdateView(viewModel: ForceUpdateViewModel(reason: .requiresOSUpdate, coordinator: nil))
}

#Preview("Brick") {
    ForceUpdateView(viewModel: ForceUpdateViewModel(reason: .brick, coordinator: nil))
}
