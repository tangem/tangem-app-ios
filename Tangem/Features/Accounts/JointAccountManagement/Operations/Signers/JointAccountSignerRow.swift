//
//  JointAccountSignerRow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// Where one member of a joint account stands on one operation: the answer in the subtitle, echoed by an
/// icon-only badge. A member yet to answer gets no badge and their name set back to the secondary colour.
struct JointAccountSignerRow: View {
    let viewData: ViewData

    var body: some View {
        Row(title: viewData.name, subtitle: viewData.answer.subtitle)
            .start { avatar }
            .end { badge }
            .overrideTextColors(.init(title: viewData.answer.nameColor))
    }

    private var avatar: some View {
        AddressBookContactNameIconView(viewData: viewData.icon, size: Constants.avatarDiameter)
    }

    @ViewBuilder
    private var badge: some View {
        if let appearance = viewData.answer.badge {
            Circle()
                .fill(appearance.background)
                .frame(size: Constants.badgeSize)
                .overlay {
                    appearance.icon.image
                        .renderingMode(.template)
                        .foregroundStyle(appearance.iconColor)
                }
        }
    }
}

// MARK: - Auxiliary types

extension JointAccountSignerRow {
    struct ViewData: Identifiable {
        /// The member's owner address, which is what tells two members of one name apart.
        let id: String
        let icon: AddressBookContactNameIconViewData
        let name: String
        let answer: Answer
    }

    /// What the member did about this operation. The endpoint reports only the members that answered, so
    /// ``waiting`` is worked out from the account's composition rather than read off the response.
    enum Answer {
        /// The member who created the operation, which signs it in the same act.
        case created(at: String)
        case signed(at: String)
        /// Stated without a moment: the copy for a declined answer carries no time.
        case declined
        case waiting
    }
}

// MARK: - Answer presentation

private extension JointAccountSignerRow.Answer {
    var subtitle: String {
        switch self {
        case .created(let time): Localization.jointOperationCreatedAt(time)
        case .signed(let time): Localization.jointOperationSignedAt(time)
        case .declined: Localization.jointOperationDeclined
        case .waiting: Localization.jointOperationWaitingToSign
        }
    }

    /// Nil leaves the row's own colour in place; a member yet to answer is set back to the secondary one.
    var nameColor: Color? {
        switch self {
        case .created, .signed, .declined: nil
        case .waiting: DesignSystem.Color.textSecondary
        }
    }

    var badge: JointAccountSignerRowBadge? {
        switch self {
        case .created, .signed:
            JointAccountSignerRowBadge(
                icon: DesignSystem.Icons.Checkmark.regular16,
                iconColor: DesignSystem.Color.iconStatusSuccess,
                background: DesignSystem.Color.bgStatusSuccessSubtle
            )
        case .declined:
            JointAccountSignerRowBadge(
                icon: DesignSystem.Icons.Cross.regular16,
                iconColor: DesignSystem.Color.iconStatusError,
                background: DesignSystem.Color.bgStatusErrorSubtle
            )
        case .waiting:
            nil
        }
    }
}

/// - Note: Drawn here rather than with the design system's badge, which is label-centric: this one carries an icon
///   and no text at all, and an empty label would leave its text padding behind.
struct JointAccountSignerRowBadge {
    let icon: ImageType
    let iconColor: Color
    let background: Color
}

// MARK: - Constants

private extension JointAccountSignerRow {
    enum Constants {
        static let avatarDiameter: CGFloat = 40
        static let badgeSize = CGSize(bothDimensions: 24)
    }
}
