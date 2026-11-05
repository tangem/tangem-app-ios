//
//  ButtonStack.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct ButtonStack: View {
    private let buttons: [Button]

    @Environment(\.isEnabled) private var isEnabled

    public init(_ button: Button) {
        buttons = [button]
    }

    public init(_ first: Button, _ second: Button) {
        buttons = [first, second]
    }

    public init(_ first: Button, _ second: Button, _ third: Button) {
        buttons = [first, second, third]
    }

    public var body: some View {
        HStack(spacing: Metrics.spacing) {
            ForEach(indexed: buttons, id: \.0) { _, button in
                button
                    .styleType(.ghost)
                    .size(.x9)
                    .horizontalLayout(.intrinsic)
            }
        }
        .padding(Metrics.padding)
        .tangemMaterialSurface(in: Capsule(), interactive: isEnabled)
        .deferringPressFeedbackToGlass()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Metrics

private extension ButtonStack {
    enum Metrics {
        static let spacing: CGFloat = 4
        static let padding: CGFloat = 4
    }
}
