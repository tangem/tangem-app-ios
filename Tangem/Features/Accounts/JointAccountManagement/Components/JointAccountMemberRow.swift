//
//  JointAccountMemberRow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// A card of one member slot of the joint account composition: an avatar, who holds the slot, and one trailing control.
struct JointAccountMemberRow: View {
    let avatar: Avatar
    let title: String
    let subtitle: String
    let accessory: Accessory

    var body: some View {
        Row(title: title, subtitle: subtitle)
            .start { avatarView }
            .end { accessoryView }
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var avatarView: some View {
        switch avatar {
        case .member(let viewData):
            AddressBookContactNameIconView(viewData: viewData, size: Constants.avatarDiameter)
        case .emptySlot:
            JointAccountMemberCircle(state: .empty, diameter: Constants.avatarDiameter)
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .info(let action):
            TangemUI.Button(
                icon: DesignSystem.Icons.Info.regular20,
                accessibilityLabel: title,
                action: action
            )
            .styleType(.secondary)
            .size(.x8)
        case .invite(let action):
            TangemUI.Button(
                label: Localization.jointAccountInviteMembersInvite,
                accessibilityLabel: nil,
                action: action
            )
            .styleType(.secondary)
            .size(.x8)
        }
    }
}

// MARK: - Auxiliary types

extension JointAccountMemberRow {
    enum Avatar {
        case member(AddressBookContactNameIconViewData)
        case emptySlot
    }

    enum Accessory {
        case info(action: () -> Void)
        case invite(action: () -> Void)
    }
}

// MARK: - Constants

private extension JointAccountMemberRow {
    enum Constants {
        static let avatarDiameter: CGFloat = 40
    }
}
