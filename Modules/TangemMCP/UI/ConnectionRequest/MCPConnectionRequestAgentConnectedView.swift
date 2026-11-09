//
//  MCPConnectionRequestAgentConnectedView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MCPConnectionRequestAgentConnectedView: View {
    let viewModel: MCPConnectionRequestAgentConnectedViewModel

    var body: some View {
        VStack(spacing: 32) {
            icon
            textSection
            proceedButton
        }
        .padding(.top, 32)
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusInfoSubtle)
                .frame(width: 72, height: 72)

            DesignSystem.Icons.Success.regular28.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconBrand)
                .frame(width: 28, height: 28)
        }
    }

    private var textSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.state.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(viewModel.state.body)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
    }

    private var proceedButton: some View {
        TangemUI.Button(
            label: viewModel.state.doneButtonTitle,
            accessibilityLabel: nil,
            action: { viewModel.handle(action: .doneButtonTapped) }
        )
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.top, 8)
    }
}
