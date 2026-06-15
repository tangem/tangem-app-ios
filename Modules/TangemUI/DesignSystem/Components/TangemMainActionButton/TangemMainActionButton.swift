//
//  TangemMainActionButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemMainActionButton: View {
    private let title: String
    private let icon: ImageType
    private let action: () -> Void
    private let reasonTapWhenDisabled: (() -> Void)?

    @Environment(\.isEnabled) private var isEnabled

    public init(
        title: String,
        icon: ImageType,
        action: @escaping () -> Void,
        reasonTapWhenDisabled: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.reasonTapWhenDisabled = reasonTapWhenDisabled
    }

    public var body: some View {
        VStack(spacing: SizeUnit.x2.value) {
            TangemButtonV2(icon: icon, accessibilityLabel: nil, action: action)
                .size(Size.buttonSize)
                .styleType(.material(.glass))

            Text(title)
                .style(
                    .Tangem.Subheadline.medium,
                    color: ActionControlAppearance.contentColor(isEnabled: isEnabled)
                )
                // [REDACTED_TODO_COMMENT]
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(.rect)
                .onTapGesture(perform: action)
        }
        .overlay {
            if !isEnabled, let reasonTapWhenDisabled {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture(perform: reasonTapWhenDisabled)
                    .environment(\.isEnabled, true)
            }
        }
    }
}

// MARK: - Layout

public extension TangemMainActionButton {
    enum Size {
        static let buttonSize: TangemButtonV2.Size = .x14
        public static var buttonSide: CGFloat { buttonSize.height }
    }
}
