//
//  MCPSendIntentView.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI

struct MCPSendIntentView: View {
    let viewModel: MCPSendIntentViewModel
    let kingfisherImageCache: ImageCache

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var tokenIconHasAppeared = false

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: DesignSystem.Color.bgPrimary,
                closeButtonAction: { viewModel.handle(action: .closeButtonTapped) }
            )

            VStack(spacing: 16) {
                MCPIntentTokenIconView(state: viewModel.state.tokenIcon, hasAppeared: tokenIconHasAppeared)
                    .offset(x: tokenIconHasAppeared ? 0 : 28)
                    .animation(.mcpIntentIconsAppear(reduceMotion: accessibilityReduceMotion), value: tokenIconHasAppeared)

                MCPIntentTitleView(title: viewModel.state.title)

                MCPIntentDescriptionSectionView(section: viewModel.state.intentDescription, kingfisherImageCache: kingfisherImageCache)

                MCPIntentPrimaryButton(title: viewModel.state.proceedButtonTitle) {
                    viewModel.handle(action: .primaryButtonTapped)
                }
            }
            .padding([.horizontal, .bottom], 16)
        }
        .onAppear {
            tokenIconHasAppeared = true
        }
        .mcpIntentSheetConfiguration()
    }
}
