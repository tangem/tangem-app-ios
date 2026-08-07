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
        .backportTranslucentNavigationBar()
        .alert(item: $viewModel.alert, content: { $0.alert })
        .safeAreaInset(edge: .bottom) { footer }
        .onAppear {
            isNameFocused = true
        }
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
        let label = AttributedString(Localization.commonCreateAccount)

        return TangemUI.Button(label: label, accessibilityLabel: nil) {
            viewModel.onCreateTap()
        }
        .content(.label(label, iconStart: nil, iconEnd: viewModel.createButtonIcon))
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .disabled(viewModel.createButtonDisabled)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background {
            Fade(position: .bottom)
                .blurred()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
