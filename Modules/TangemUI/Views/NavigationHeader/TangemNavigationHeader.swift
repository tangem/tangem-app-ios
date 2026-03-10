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
    private let secondaryTrailingAction: (() -> Void)?
    private let trailingAction: () -> Void
    private let accessibilityIdentifiers: AccessibilityIdentifiers

    public init(
        secondaryTrailingAction: (() -> Void)? = nil,
        trailingAction: @escaping () -> Void,
        accessibilityIdentifiers: AccessibilityIdentifiers
    ) {
        self.secondaryTrailingAction = secondaryTrailingAction
        self.trailingAction = trailingAction
        self.accessibilityIdentifiers = accessibilityIdentifiers
    }

    public var body: some View {
        HStack {
            leadingIcon

            Spacer()

            trailingMenuButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(alignment: .top) {
            // iOS 26+ uses native scrollEdgeEffect for blur
            if #available(iOS 26.0, *) {
                EmptyView()
            } else {
                VariableBlur(direction: .down)
                    .dimmingAlpha(.constant(alpha: 0.5))
                    .dimmingOvershoot(nil)
                    .ignoresSafeArea()
            }
        }
    }

    private var leadingIcon: some View {
        Assets.tangemIcon.image
            .resizable()
            .frame(size: CGSize(bothDimensions: SizeUnit.x8.value))
            .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
    }

    private var trailingMenuButton: some View {
        HStack(spacing: 8) {
            if let secondaryTrailingAction {
                if let secondaryTrailingButton = accessibilityIdentifiers.secondaryTrailingButton,
                   let secondaryTrailingButtonLabel = accessibilityIdentifiers.secondaryTrailingButtonLabel {
                    TangemButton(content: .icon(Assets.Glyphs.scanQrIcon), action: secondaryTrailingAction)
                        .setCornerStyle(.rounded)
                        .setStyleType(.secondary)
                        .setSize(.x10)
                        .accessibility(label: Text(secondaryTrailingButtonLabel))
                        .accessibilityIdentifier(secondaryTrailingButton)
                } else {
                    TangemButton(content: .icon(Assets.Glyphs.scanQrIcon), action: secondaryTrailingAction)
                        .setCornerStyle(.rounded)
                        .setStyleType(.secondary)
                        .setSize(.x10)
                }
            }

            TangemButton(content: .icon(Assets.horizontalDots), action: trailingAction)
                .setCornerStyle(.rounded)
                .setStyleType(.secondary)
                .setSize(.x10)
                .accessibility(label: Text(accessibilityIdentifiers.trailingButtonLabel))
                .accessibilityIdentifier(accessibilityIdentifiers.trailingButton)
        }
    }
}

// MARK: - AccessibilityIdentifiers

public extension TangemNavigationHeader {
    struct AccessibilityIdentifiers {
        public let trailingButton: String
        public let trailingButtonLabel: String
        public let secondaryTrailingButton: String?
        public let secondaryTrailingButtonLabel: String?

        public init(
            trailingButton: String,
            trailingButtonLabel: String,
            secondaryTrailingButton: String? = nil,
            secondaryTrailingButtonLabel: String? = nil
        ) {
            self.trailingButton = trailingButton
            self.trailingButtonLabel = trailingButtonLabel
            self.secondaryTrailingButton = secondaryTrailingButton
            self.secondaryTrailingButtonLabel = secondaryTrailingButtonLabel
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack {
        TangemNavigationHeader(
            trailingAction: {},
            accessibilityIdentifiers: .init(trailingButton: "preview", trailingButtonLabel: "Preview")
        )
        Spacer()
    }
    .background(Color.Tangem.Surface.level1)
}
#endif
