//
//  MCPIntentIssueView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MCPIntentIssueView: View {
    @ObservedObject var viewModel: MCPIntentIssueViewModel

    var body: some View {
        VStack(spacing: 16) {
            Avatar(Avatar.Content.icon(iconViewAsset, appearance: iconAppearance), size: .size72)

            MCPIntentTitleView(title: viewModel.state.issue.title, subtitle: viewModel.state.issue.subtitle)

            TangemUI.Button(label: viewModel.state.primaryButton.title, accessibilityLabel: nil) {
                viewModel.handle(action: .primaryButtonTapped)
            }
            .loading(.spinner(if: viewModel.state.primaryButton.isLoading))
            .styleType(.primary)
            .size(.x12)
            .horizontalLayout(.infinity)
            .padding(.top, 8)
        }
        .onAppear {
            viewModel.handle(action: .viewDidAppear)
        }
    }

    private var iconViewAsset: ImageType {
        switch viewModel.state.issue.severity {
        case .notice: DesignSystem.Icons.Info.regular28
        case .error: DesignSystem.Icons.Warning.regular28
        }
    }

    private var iconAppearance: Avatar.IconAppearance {
        switch viewModel.state.issue.severity {
        case .notice: Avatar.IconAppearance.info
        case .error: Avatar.IconAppearance.warning
        }
    }
}
