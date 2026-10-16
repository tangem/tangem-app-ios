//
//  TangemDot.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct TangemDot: View {
    private let selected: Bool

    @ScaledMetric private var dotWidth: CGFloat
    @ScaledMetric private var dotHeight: CGFloat
    @ScaledMetric private var horizontalPadding: CGFloat
    @ScaledMetric private var verticalPadding: CGFloat

    private var color: Color {
        selected ? .Tangem.Graphic.Neutral.primary : .Tangem.Graphic.Neutral.tertiary
    }

    public init(selected: Bool = false, size: Size = .x2) {
        self.selected = selected
        _dotWidth = ScaledMetric(wrappedValue: Self.dotWidth(size: size))
        _dotHeight = ScaledMetric(wrappedValue: Self.dotHeight(size: size))
        _horizontalPadding = ScaledMetric(wrappedValue: Self.horizontalPadding(size: size))
        _verticalPadding = ScaledMetric(wrappedValue: Self.verticalPadding(size: size))
    }

    public var body: some View {
        color
            .frame(width: dotWidth, height: dotHeight)
            .clipShape(.capsule)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
    }
}

// MARK: - Calculations

private extension TangemDot {
    static func dotWidth(size: Size) -> CGFloat {
        switch size {
        case .x1: 4
        case .x1_5: 6
        case .x2: 8
        }
    }

    static func dotHeight(size: Size) -> CGFloat {
        switch size {
        case .x1: 4
        case .x1_5: 6
        case .x2: 8
        }
    }

    static func horizontalPadding(size: Size) -> CGFloat {
        switch size {
        case .x1: 2
        case .x1_5: 1
        case .x2: 0
        }
    }

    static func verticalPadding(size: Size) -> CGFloat {
        switch size {
        case .x1: 2
        case .x1_5: 1
        case .x2: 0
        }
    }
}

// MARK: - Types

public extension TangemDot {
    enum Size {
        case x1
        case x1_5
        case x2
    }
}
