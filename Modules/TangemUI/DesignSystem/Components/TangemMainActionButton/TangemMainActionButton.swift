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
            TangemButton(content: .icon(icon), action: action)
                .setSize(.x15)
                .setCornerStyle(.rounded)
                .setStyleType(.secondary)
                .actionControlDimmed(isEnabled: isEnabled)

            Text(title)
                .style(
                    .Tangem.Subheadline.medium,
                    color: ActionControlAppearance.contentColor(isEnabled: isEnabled)
                )
                .lineLimit(nil)
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
