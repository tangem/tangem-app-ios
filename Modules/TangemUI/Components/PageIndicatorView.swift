//
//  PageIndicatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI
import TangemAssets

public struct PageIndicatorViewRedesign: View {
    private let totalPages: Int
    private let currentIndex: Int

    public init(totalPages: Int, currentIndex: Int) {
        self.totalPages = totalPages
        self.currentIndex = currentIndex
    }

    private let maxVisibleDots = 5

    public var body: some View {
        HStack(spacing: .unit(.x2)) {
            ForEach(visibleIndices, id: \.self) { index in
                dot(for: index)
            }
        }
        .padding(.horizontal, .unit(.x3))
        .frame(height: 32)
        .background {
            Capsule()
                .fill(Color.Tangem.Tabs.backgroundSecondary)
                .background(.ultraThinMaterial, in: .capsule)
        }
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }

    private func dot(for index: Int) -> some View {
        let innerSize = dotInnerSize(for: index)
        let isActive = index == currentIndex
        let color = isActive
            ? Color.Tangem.Graphic.Neutral.primary
            : Color.Tangem.Graphic.Neutral.tertiary

        return Circle()
            .fill(color)
            .frame(width: innerSize, height: innerSize)
            .frame(width: 8, height: 8)
    }

    private func dotInnerSize(for index: Int) -> CGFloat {
        let distance = abs(index - currentIndex)

        switch layoutPosition {
        case .pinnedLeft, .pinnedRight:
            switch distance {
            case 0: return 8
            case 1, 2: return 6
            default: return 4
            }
        case .centered:
            switch distance {
            case 0: return 8
            case 1: return 6
            default: return 4
            }
        }
    }

    private var visibleIndices: [Int] {
        guard totalPages > 0 else { return [] }
        guard totalPages > maxVisibleDots else { return Array(0 ..< totalPages) }

        let (lowerBound, upperBound) = windowBounds
        return Array(lowerBound ..< upperBound)
    }

    private var windowBounds: (lower: Int, upper: Int) {
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

    private var layoutPosition: LayoutPosition {
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

private extension PageIndicatorViewRedesign {
    enum LayoutPosition {
        case pinnedLeft
        case centered
        case pinnedRight
    }
}
