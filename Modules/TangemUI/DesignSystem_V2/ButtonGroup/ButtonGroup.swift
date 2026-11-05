//
//  ButtonGroup.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct ButtonGroup: View, Setupable {
    private let start: Button?
    private let end: Button
    private var orientation: Orientation = .vertical

    public init(start: Button? = nil, end: Button) {
        self.start = start
        self.end = end
    }

    public var body: some View {
        layout {
            if let start {
                styled(start)
            }

            styled(end)
        }
    }

    private var layout: AnyLayout {
        switch orientation {
        case .vertical: AnyLayout(VStackLayout(spacing: Metrics.spacing))
        case .horizontal: AnyLayout(HStackLayout(spacing: Metrics.spacing))
        }
    }

    private func styled(_ button: Button) -> Button {
        button
            .size(.x12)
            .horizontalLayout(.infinity)
    }
}

// MARK: - Setupable

public extension ButtonGroup {
    func orientation(_ orientation: Orientation) -> Self {
        map { $0.orientation = orientation }
    }
}

// MARK: - Metrics

private extension ButtonGroup {
    enum Metrics {
        static let spacing: CGFloat = 8
    }
}
