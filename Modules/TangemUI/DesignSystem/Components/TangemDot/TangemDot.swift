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
        _dotWidth = ScaledMetric(wrappedValue: Self.dotWidth(selected: selected, size: size))
        _dotHeight = ScaledMetric(wrappedValue: Self.dotHeight(size: size))
        _horizontalPadding = ScaledMetric(wrappedValue: Self.horizontalPadding(selected: selected, size: size))
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
    static func dotWidth(selected: Bool, size: Size) -> CGFloat {
        let baseWidth: CGFloat = switch size {
        case .x1: SizeUnit.x1.value
        case .x1_5: SizeUnit.x1_5.value
        case .x2: SizeUnit.x2.value
        }
        let factor: CGFloat = selected ? 2.0 : 1.0
        return baseWidth * factor
    }

    static func dotHeight(size: Size) -> CGFloat {
        switch size {
        case .x1: SizeUnit.x1.value
        case .x1_5: SizeUnit.x1_5.value
        case .x2: SizeUnit.x2.value
        }
    }

    static func horizontalPadding(selected: Bool, size: Size) -> CGFloat {
        let basePadding: CGFloat = switch size {
        case .x1: SizeUnit.half.value
        case .x1_5: SizeUnit.quarter.value
        case .x2: SizeUnit.zero.value
        }
        let factor: CGFloat = selected ? 2.0 : 1.0
        return basePadding * factor
    }

    static func verticalPadding(size: Size) -> CGFloat {
        switch size {
        case .x1: SizeUnit.half.value
        case .x1_5: SizeUnit.quarter.value
        case .x2: SizeUnit.zero.value
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
