//
//  ButtonGroupSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
import TangemUI

enum ButtonGroupSnapshotScenario: String, SnapshotScenario {
    case vertical
    case horizontal
    case horizontalRTL
    case horizontalLargeText

    var canvases: [SnapshotCanvas] {
        switch self {
        case .vertical: [.fixed(width: 402, height: 200)]
        case .horizontal, .horizontalRTL: [.fixed(width: 402, height: 144)]
        case .horizontalLargeText: [.fixed(width: 402, height: 200)]
        }
    }

    var layoutDirection: LayoutDirection {
        self == .horizontalRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .horizontalLargeText ? .xxxLarge : .large
    }

    @MainActor
    var body: some View {
        VStack(spacing: 16) {
            ButtonGroup(start: button("Learn more").styleType(.secondary(.default)), end: button("Got it"))
                .orientation(orientation)

            ButtonGroup(end: button("Got it"))
                .orientation(orientation)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

@MainActor
private extension ButtonGroupSnapshotScenario {
    var orientation: ButtonGroup.Orientation {
        self == .vertical ? .vertical : .horizontal
    }

    func button(_ label: String) -> TangemUI.Button {
        TangemUI.Button(label: label, accessibilityLabel: nil, action: {})
            .styleType(.primary)
    }
}
