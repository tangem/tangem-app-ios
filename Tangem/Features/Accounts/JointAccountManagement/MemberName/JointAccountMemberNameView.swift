//
//  JointAccountMemberNameView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountMemberNameView: View {
    @ObservedObject var viewModel: JointAccountMemberNameViewModel

    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: 24)) {
                titleView

                content
            }
            .horizontalPadding(24)
        }
        .toolbar {
            NavigationToolbarButton
                .close(placement: .topBarTrailing, action: viewModel.onCloseTap)
        }
        .translucentNavigationBar()
        .alert(item: $viewModel.alert, content: { $0.alert })
        .safeAreaInset(edge: .bottom) { footer }
        .focusOnAppear($isNameFocused)
    }

    private var titleView: some View {
        JointAccountHeaderTitle(
            title: Localization.jointAccountNameTitle,
            subtitle: Localization.jointAccountNameSubtitle
        )
        .padding(.top, 12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            JointAccountMemberNameField(
                text: $viewModel.name,
                isFocused: $isNameFocused,
                title: Localization.jointAccountNameDisplayName,
                maxLength: viewModel.nameMaxLength,
                hasError: viewModel.hasNameError
            )

            Text(Localization.jointAccountNameHint)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .padding(.top, 12)
    }

    private var footer: some View {
        SigningActionButtonView(
            type: viewModel.submitButtonType,
            title: viewModel.submitButtonTitle,
            isLoading: viewModel.isSubmitting,
            isDisabled: viewModel.submitButtonDisabled,
            action: viewModel.onSubmitTap
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background {
            Fade(position: .bottom)
                .blurred()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
