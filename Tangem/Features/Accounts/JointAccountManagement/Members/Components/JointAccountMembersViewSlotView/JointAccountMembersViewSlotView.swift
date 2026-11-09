//
//  JointAccountMembersViewSlotView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountMembersViewSlotView: View {
    @ObservedObject var viewModel: JointAccountMembersViewSlotViewModel

    var body: some View {
        Row(title: viewModel.content.title, subtitle: viewModel.content.subtitle)
            .start { avatarView }
            .end { endView }
            .onTap(action: viewModel.isTappable ? viewModel.onTap : nil)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var avatarView: some View {
        switch viewModel.content.avatar {
        case .member(let viewData):
            AddressBookContactNameIconView(viewData: viewData, size: Constants.avatarDiameter)
        case .vacant:
            JointAccountMemberCircle(state: .vacant, diameter: Constants.avatarDiameter)
        }
    }

    @ViewBuilder
    private var endView: some View {
        if let status = viewModel.content.status {
            statusBadge(status)
        }

        switch viewModel.content.accessory {
        case .empty:
            EmptyView()
        case .invite:
            TangemUI.Button(
                label: Localization.jointAccountInviteMembersInvite,
                accessibilityLabel: nil,
                action: viewModel.onInviteTap
            )
            .styleType(.secondary(.default))
            .size(.x8)
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: JointAccountMembersViewSlotViewModel.Status) -> some View {
        switch status {
        case .joined:
            Badge(label: Localization.jointAccountMembersRoleJoined, accessibilityLabel: nil)
                .appearance(.info)
        case .notConfirmed:
            Badge(label: Localization.jointAccountMembersStatusNotConfirmed, accessibilityLabel: nil)
                .appearance(.neutral)
        }
    }
}

// MARK: - Constants

private extension JointAccountMembersViewSlotView {
    enum Constants {
        static let avatarDiameter: CGFloat = 40
        static let cornerRadius: CGFloat = 24
    }
}
