//
//  JointAccountMembersView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct JointAccountMembersView: View {
    @ObservedObject var viewModel: JointAccountMembersViewModel
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let dismissStyle: DismissStyle

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: Constants.sectionSpacing)) {
                content
            }
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                footer
            }
        }
        .topNavigation(
            leading: dismissStyle == .back ? .automatic : .none,
            onClose: dismissStyle == .close ? viewModel.onCloseTap : nil
        ) {
            if case .navigationBar(let text) = viewModel.title {
                TopNavigationTitleContent(title: text)
            }
        }
        .onWillAppear(perform: viewModel.onWillAppear)
        .onWillDisappear(perform: viewModel.onWillDisappear)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.title {
        case .header(let text, let subtitle):
            JointAccountHeaderTitle(title: text, subtitle: subtitle)
                .padding(.top, Constants.titleTopPadding)
                .padding(.horizontal, Constants.titleHorizontalPadding)

            JointAccountMembersSummaryView(
                summary: viewModel.summary,
                onApprovalsInfoTap: viewModel.onApprovalsInfoTap
            )

            VStack(alignment: .leading, spacing: Constants.rowSpacing) {
                Text(Localization.jointAccountMembersTitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .padding(.vertical, Constants.sectionHeaderVerticalPadding)

                slots
            }

        case .navigationBar, .none:
            VStack(alignment: .leading, spacing: Constants.rowSpacing) {
                slots
            }
        }
    }

    private var slots: some View {
        ForEach(viewModel.slots) { slot in
            JointAccountMembersViewSlotView(viewModel: slot)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.footer != nil || viewModel.actions.isNotEmpty {
            VStack(spacing: Constants.footerSpacing) {
                if let footer = viewModel.footer {
                    Text(footer)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                ForEach(viewModel.actions, id: \.self) { action in
                    actionButton(action)
                }
            }
            .padding(.horizontal, Constants.footerHorizontalPadding)
            .padding(.vertical, Constants.footerVerticalPadding)
            .background {
                Fade(position: .bottom)
                    .variant(.hard)
                    .blurred(!reduceTransparency)
                    .padding(.top, -Constants.footerFadeOverhang)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    @ViewBuilder
    private func actionButton(_ action: JointAccountMembersViewModel.Action) -> some View {
        switch action {
        case .confirmSharedAddress(let isEnabled):
            SigningActionButtonView(
                type: viewModel.signingActionButtonType,
                title: Localization.jointAccountConfirmSharedAddress,
                isLoading: viewModel.isActivating,
                isDisabled: !isEnabled,
                action: { viewModel.onActionTap(action) }
            )
        }
    }
}

// MARK: - DismissStyle

extension JointAccountMembersView {
    enum DismissStyle {
        case back
        case close
    }
}

// MARK: - Constants

private extension JointAccountMembersView {
    enum Constants {
        static let sectionSpacing: CGFloat = 20
        static let rowSpacing: CGFloat = 8
        static let titleTopPadding: CGFloat = 12
        static let titleHorizontalPadding: CGFloat = 4
        static let sectionHeaderVerticalPadding: CGFloat = 8
        static let footerSpacing: CGFloat = 12
        static let footerHorizontalPadding: CGFloat = 16
        static let footerVerticalPadding: CGFloat = 8
        static let footerFadeOverhang: CGFloat = 16
    }
}
