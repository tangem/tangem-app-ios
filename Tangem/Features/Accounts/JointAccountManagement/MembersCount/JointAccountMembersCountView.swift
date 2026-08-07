//
//  JointAccountMembersCountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountMembersCountView: View {
    @ObservedObject var viewModel: JointAccountMembersCountViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary

            Text("[REDACTED_TODO_COMMENT]")
        }
        .ignoresSafeArea()
        .toolbar {
            NavigationToolbarButton
                .close(placement: .topBarTrailing, action: viewModel.onCloseTap)
        }
        .backportTranslucentNavigationBar()
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var footer: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil
        ) {
            viewModel.onContinueTap()
        }
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background {
            Fade(position: .bottom)
                .blurred()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Previews

#Preview {
    JointAccountMembersCountView(
        viewModel: JointAccountMembersCountViewModel(
            creationHelper: JointAccountCreationHelper(),
            coordinator: nil
        )
    )
}
