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
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: 24)) {
                titleView

                membersView

                countersView
            }
        }
        .toolbar {
            NavigationToolbarButton
                .close(placement: .topBarTrailing, action: viewModel.onCloseTap)
        }
        .backportTranslucentNavigationBar()
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var titleView: some View {
        JointAccountHeaderTitle(
            title: Localization.jointAccountMembersTitle,
            subtitle: Localization.jointAccountMembersSubtitle(viewModel.signersCount, viewModel.membersCount)
        )
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var membersView: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.memberStates.enumerated()), id: \.offset) { _, state in
                JointAccountMemberCircle(state: state)
            }
        }
        .padding(.horizontal, 8)
    }

    private var countersView: some View {
        VStack(spacing: .zero) {
            Row(
                title: Localization.jointAccountMembersTotalTitle,
                subtitle: Localization.jointAccountMembersTotalSubtitle(viewModel.membersCountRange.upperBound)
            )
            .showDivider()
            .end { JointAccountCounter(value: $viewModel.membersCount, range: viewModel.membersCountRange) }

            Row(
                title: Localization.jointAccountMembersSignersTitle,
                subtitle: Localization.jointAccountMembersSignersSubtitle
            )
            .end { JointAccountCounter(value: $viewModel.signersCount, range: viewModel.signersCountRange) }
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
