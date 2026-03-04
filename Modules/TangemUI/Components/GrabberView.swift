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
    public init() {}

    public var body: some View {
        Capsule(style: .continuous)
            .fill(Color.Tangem.Graphic.Neutral.primaryInverted)
            .frame(size: CGSize(width: 40, height: 4.0))
            .padding(.vertical, 4)
            .infinityFrame(axis: .horizontal)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.grabber)
    }
}
