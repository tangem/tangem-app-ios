//
//  MCPIntentStatusView.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MCPIntentStatusView: View {
    let viewModel: MCPIntentStatusViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: DesignSystem.Color.bgPrimary,
                closeButtonAction: { viewModel.handle(action: .closeButtonTapped) }
            )

            VStack(spacing: 16) {
                Avatar(avatarContent, size: .size72)

                MCPIntentTitleView(title: viewModel.state.title, subtitle: viewModel.state.subtitle)

                MCPIntentPrimaryButton(title: viewModel.state.buttonTitle) {
                    viewModel.handle(action: .primaryButtonTapped)
                }
            }
            .padding([.horizontal, .bottom], 16)
        }
        .mcpIntentSheetConfiguration()
    }

    private var avatarContent: Avatar.Content {
        switch viewModel.state.tone {
        case .warning: .icon(DesignSystem.Icons.Warning.regular28, appearance: .warning)
        case .info: .icon(DesignSystem.Icons.Info.regular28, appearance: .info)
        }
    }
}
