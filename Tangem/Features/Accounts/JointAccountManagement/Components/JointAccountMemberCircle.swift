//
//  JointAccountMemberCircle.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// One member slot of the joint account composition, in one of the three states the design defines.
struct JointAccountMemberCircle: View {
    let state: State

    var body: some View {
        ZStack {
            Circle()
                .fill(state.backgroundColor)

            border

            glyph
        }
        .frame(width: Constants.diameter, height: Constants.diameter)
    }

    private var border: some View {
        Circle()
            .strokeBorder(state.borderColor, style: state.borderStyle)
    }

    @ViewBuilder
    private var glyph: some View {
        if let iconColor = state.iconColor {
            Assets.Accounts.family.image.foregroundStyle(iconColor)
        }
    }
}

// MARK: - State

extension JointAccountMemberCircle {
    enum State {
        case active
        case filled
        case empty
    }
}

private extension JointAccountMemberCircle.State {
    var backgroundColor: Color {
        switch self {
        case .active: DesignSystem.Color.bgStatusInfoSubtle
        case .filled: DesignSystem.Color.bgOpaquePrimary
        case .empty: .clear
        }
    }

    var borderColor: Color {
        switch self {
        case .active: DesignSystem.Color.borderStatusInfoSubtle
        case .filled: DesignSystem.Color.borderPrimary
        case .empty: DesignSystem.Color.borderSecondary
        }
    }

    var borderStyle: StrokeStyle {
        switch self {
        case .active, .filled:
            StrokeStyle(lineWidth: JointAccountMemberCircle.Constants.borderWidth)
        case .empty:
            StrokeStyle(
                lineWidth: JointAccountMemberCircle.Constants.borderWidth,
                dash: [JointAccountMemberCircle.Constants.borderDash]
            )
        }
    }

    var iconColor: Color? {
        switch self {
        case .active: DesignSystem.Color.iconStatusInfo
        case .filled: DesignSystem.Color.iconSecondary
        case .empty: nil
        }
    }
}

// MARK: - Constants

private extension JointAccountMemberCircle {
    enum Constants {
        static let diameter: CGFloat = 48
        static let borderWidth: CGFloat = 1.5

        /// The design keeps the dash at 3/28 of the diameter, which is its 5.142857 for a 48pt circle.
        /// A single-element pattern means the gaps between the dashes measure the same.
        static let borderDash: CGFloat = diameter * 3 / 28
    }
}
