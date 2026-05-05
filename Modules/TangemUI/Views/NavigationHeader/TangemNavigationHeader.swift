//
//  TangemNavigationHeader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import BlurSwiftUI

public struct TangemNavigationHeader: View {
    private let secondaryTrailingAction: ActionInfo?
    private let trailingAction: ActionInfo

    public init(
        secondaryTrailingAction: ActionInfo? = nil,
        trailingAction: ActionInfo
    ) {
        self.secondaryTrailingAction = secondaryTrailingAction
        self.trailingAction = trailingAction
    }

    public var body: some View {
        HStack(spacing: 0) {
            leadingIcon

            Spacer()

            trailingMenuButton
        }
        .padding(.horizontal, .unit(.x4))
        .padding(.top, .unit(.x2))
        .padding(.bottom, .unit(.x3))
        .background(alignment: .top) {
            VariableBlur(direction: .down)
                .dimmingAlpha(.constant(alpha: 0.5))
                .dimmingOvershoot(nil)
                .ignoresSafeArea()
        }
    }

    private var leadingIcon: some View {
        LeadingIcon()
    }

    private var trailingMenuButton: some View {
        TrailingButtons(
            secondaryAction: secondaryTrailingAction,
            action: trailingAction
        )
    }
}

// MARK: - ActionInfo

public extension TangemNavigationHeader {
    struct ActionInfo {
        public let action: () -> Void
        public let accessibilityIdentifier: String
        public let accessibilityLabel: String

        public init(
            action: @escaping () -> Void,
            accessibilityIdentifier: String,
            accessibilityLabel: String
        ) {
            self.action = action
            self.accessibilityIdentifier = accessibilityIdentifier
            self.accessibilityLabel = accessibilityLabel
        }
    }
}

// MARK: - LeadingIcon

public extension TangemNavigationHeader {
    struct LeadingIcon: View {
        @ScaledSize private var iconSize = CGSize(bothDimensions: .unit(.x8))

        public init() {}

        public var body: some View {
            Assets.tangemIcon.image
                .renderingMode(.template)
                .resizable()
                .frame(size: iconSize)
                .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
        }
    }
}

// MARK: - TrailingButtons

public extension TangemNavigationHeader {
    struct TrailingButtons: View {
        private let secondaryAction: ActionInfo?
        private let action: ActionInfo

        public init(
            secondaryAction: ActionInfo? = nil,
            action: ActionInfo
        ) {
            self.secondaryAction = secondaryAction
            self.action = action
        }

        public var body: some View {
            HStack(spacing: .unit(.x2)) {
                if let secondaryAction {
                    makeButton(imageType: Assets.Glyphs.scanQrIcon, actionInfo: secondaryAction)
                }

                makeButton(imageType: Assets.horizontalDots, actionInfo: action)
            }
        }

        private func makeButton(imageType: ImageType, actionInfo: ActionInfo) -> some View {
            TangemButton(content: .icon(imageType), action: actionInfo.action)
                .setCornerStyle(.rounded)
                .setStyleType(.secondary)
                .setSize(.x10)
                .accessibility(label: Text(actionInfo.accessibilityLabel))
                .accessibilityIdentifier(actionInfo.accessibilityIdentifier)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        TangemNavigationHeader(
            trailingAction: TangemNavigationHeader.ActionInfo(
                action: {},
                accessibilityIdentifier: "preview",
                accessibilityLabel: "Preview"
            )
        )
        Spacer()
    }
    .background(Color.Tangem.Surface.level1)
}
#endif
