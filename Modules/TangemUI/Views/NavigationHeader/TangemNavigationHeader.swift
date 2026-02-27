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
    private let trailingAction: () -> Void
    private let accessibilityIdentifiers: AccessibilityIdentifiers

    public init(
        trailingAction: @escaping () -> Void,
        accessibilityIdentifiers: AccessibilityIdentifiers
    ) {
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
        TangemButton(content: .icon(Assets.horizontalDots), action: trailingAction)
            .setCornerStyle(.rounded)
            .setStyleType(.secondary)
            .setSize(.x10)
            .accessibility(label: Text(accessibilityIdentifiers.trailingButtonLabel))
            .accessibilityIdentifier(accessibilityIdentifiers.trailingButton)
    }
}

// MARK: - AccessibilityIdentifiers

public extension TangemNavigationHeader {
    struct AccessibilityIdentifiers {
        public let trailingButton: String
        public let trailingButtonLabel: String

        public init(
            trailingButton: String,
            trailingButtonLabel: String
        ) {
            self.trailingButton = trailingButton
            self.trailingButtonLabel = trailingButtonLabel
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
