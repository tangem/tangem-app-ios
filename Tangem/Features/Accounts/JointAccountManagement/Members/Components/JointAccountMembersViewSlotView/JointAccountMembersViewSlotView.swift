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
        ZStack {
            row
                .id(viewModel.contentKey)
                .transition(.blurSwap)
        }
        .onChange(of: viewModel.slot) { newSlot in
            viewModel.onContentChange(to: newSlot)
        }
    }

    private var row: some View {
        Row(title: viewModel.title, subtitle: viewModel.subtitle.text)
            .subtitleAccessory { subtitleIcon }
            .start { JointAccountMemberIconView(viewData: viewModel.icon, diameter: Constants.avatarDiameter) }
            .end { endView }
            .overrideTextColors(RowOverrideTextColors(subtitle: subtitleColor))
            .onTap(action: viewModel.isTappable ? viewModel.onTap : nil)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var subtitleIcon: some View {
        switch viewModel.subtitle {
        case .plain:
            EmptyView()
        case .expiry:
            DesignSystem.Icons.Clock.regular12.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)
        }
    }

    private var subtitleColor: Color? {
        switch viewModel.subtitle {
        case .plain: nil
        case .expiry: DesignSystem.Color.textStatusWarning
        }
    }

    @ViewBuilder
    private var endView: some View {
        switch viewModel.accessory {
        case .empty:
            EmptyView()
        case .joined:
            Badge(label: Localization.jointAccountMembersRoleJoined, accessibilityLabel: nil)
                .appearance(.info)
        case .confirmed:
            Badge(label: Localization.jointAccountMembersStatusConfirmed, accessibilityLabel: nil)
                .appearance(.success)
        case .notConfirmed:
            Badge(label: Localization.jointAccountMembersStatusNotConfirmed, accessibilityLabel: nil)
                .appearance(.neutral)
        case .invite:
            inviteButton(title: Localization.jointAccountInviteMembersInvite)
        case .reInvite:
            inviteButton(title: Localization.jointAccountInviteMembersReInvite)
        }
    }

    private func inviteButton(title: String) -> some View {
        TangemUI.Button(label: title, accessibilityLabel: nil, action: viewModel.onInviteTap)
            .styleType(.secondary(.default))
            .size(.x8)
            .loading(.spinner(if: viewModel.isLoading))
    }
}

// MARK: - Constants

private extension JointAccountMembersViewSlotView {
    enum Constants {
        static let avatarDiameter: CGFloat = 40
        static let cornerRadius: CGFloat = 24
    }
}
