//
//  GrabberView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets

public struct GrabberView: View {
    private let style: Style

    public init(style: Style = .default) {
        self.style = style
    }

    @ViewBuilder
    public var body: some View {
        switch style {
        case .default:
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: CGSize(width: 32.0, height: 4.0))
                .padding(.vertical, 8)
                .infinityFrame(axis: .horizontal)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.grabber)
        case .redesigned:
            Capsule(style: .continuous)
                .fill(Color.Tangem.Graphic.Neutral.primaryInverted)
                .frame(size: CGSize(width: 40, height: 4.0))
                .padding(.vertical, 4)
                .infinityFrame(axis: .horizontal)
                .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.grabber)
        }
    }
}

public extension GrabberView {
    enum Style {
        case `default`
        case redesigned
    }
}
