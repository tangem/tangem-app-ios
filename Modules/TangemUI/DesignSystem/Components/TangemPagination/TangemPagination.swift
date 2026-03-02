//
//  TangemPagination.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct TangemPagination: View {
    private let totalPages: Int
    private let currentIndex: Int
    private let maxVisibleDots: Int

    @ScaledMetric private var spacing: CGFloat
    @ScaledMetric private var horizontalPadding: CGFloat
    @ScaledMetric private var verticalPadding: CGFloat

    public init(totalPages: Int, currentIndex: Int, maxVisibleDots: Int = 5) {
        self.totalPages = totalPages
        self.currentIndex = currentIndex
        self.maxVisibleDots = maxVisibleDots
        _spacing = ScaledMetric(wrappedValue: SizeUnit.x2.value)
        _horizontalPadding = ScaledMetric(wrappedValue: SizeUnit.x3.value)
        _verticalPadding = ScaledMetric(wrappedValue: SizeUnit.x3.value)
    }

    public var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Color.Tangem.Tabs.backgroundPrimary)
            .clipShape(.capsule)
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }
}

// MARK: - Subviews

private extension TangemPagination {
    var content: some View {
        HStack(spacing: spacing) {
            ForEach(visibleIndices, id: \.self) { index in
                dot(for: index)
            }
        }
    }

    func dot(for index: Int) -> some View {
        let isActive = index == currentIndex
        let size = dotSize(for: index)
        return TangemDot(selected: isActive, size: size)
    }
}

// MARK: - Calculations

private extension TangemPagination {
    func dotSize(for index: Int) -> TangemDot.Size {
        let distance = abs(index - currentIndex)

        switch layoutPosition {
        case .pinnedLeft, .pinnedRight:
            switch distance {
            case 0, 1, 2: return .x2
            case 3: return .x1_5
            default: return .x1
            }
        case .centered:
            switch distance {
            case 0, 1: return .x2
            case 2: return .x1_5
            default: return .x1
            }
        }
    }

    var visibleIndices: [Int] {
        guard totalPages > 0 else { return [] }
        guard totalPages > maxVisibleDots else { return Array(0 ..< totalPages) }

        let (lowerBound, upperBound) = windowBounds
        return Array(lowerBound ..< upperBound)
    }

    var windowBounds: (lower: Int, upper: Int) {
        var lowerBound = 0

        if currentIndex <= 1 {
            lowerBound = 0
        } else if totalPages > maxVisibleDots, currentIndex >= totalPages - 3 {
            lowerBound = totalPages - maxVisibleDots
        } else if totalPages > maxVisibleDots {
            lowerBound = currentIndex - 2
        }

        let upperBound = min(lowerBound + maxVisibleDots, totalPages)
        return (lowerBound, upperBound)
    }

    var layoutPosition: LayoutPosition {
        let bounds = windowBounds

        if bounds.lower == 0, currentIndex <= bounds.lower + 1 {
            return .pinnedLeft
        }

        if bounds.upper == totalPages, currentIndex >= bounds.upper - 2 {
            return .pinnedRight
        }

        return .centered
    }
}

// MARK: - Types

private extension TangemPagination {
    enum LayoutPosition {
        case pinnedLeft
        case centered
        case pinnedRight
    }
}
