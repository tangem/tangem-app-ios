//
//  PageIndicatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI
import TangemAssets

struct PageIndicatorView: View {
    let totalPages: Int
    let currentIndex: Int

    private let backgroundSize = CGSize(width: 92, height: 32)
    private let maxVisibleDots = 5
    private let spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(visibleIndices, id: \.self) { index in
                dot(for: index)
            }
        }
        .frame(width: backgroundSize.width, height: backgroundSize.height)
        .background(
            Capsule()
                .fill(Color.Tangem.Overlay.overlaySecondary)
        )
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }

    private func dot(for index: Int) -> some View {
        let size = dotSize(for: index)

        return RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
            .fill(Color.Tangem.Text.Neutral.primaryInvertedConstant)
            .frame(width: size.width, height: size.height)
    }

    private func dotSize(for index: Int) -> CGSize {
        let distance = abs(index - currentIndex)

        switch layoutPosition {
        case .pinnedLeft, .pinnedRight:
            switch distance {
            case 0:
                return CGSize(width: 16, height: 8)
            case 1, 2:
                return CGSize(width: 8, height: 8)
            case 3:
                return CGSize(width: 6, height: 6)
            default:
                return CGSize(width: 4, height: 4)
            }
        case .centered:
            switch distance {
            case 0:
                return CGSize(width: 16, height: 8)
            case 1:
                return CGSize(width: 8, height: 8)
            case 2:
                return CGSize(width: 6, height: 6)
            default:
                return CGSize(width: 4, height: 4)
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

private extension PageIndicatorView {
    enum LayoutPosition {
        case pinnedLeft
        case centered
        case pinnedRight
    }
}

#if DEBUG

private struct InteractiveDemo: View {
    @State private var current: Int = 0
    private let total: Int = 10

    var body: some View {
        VStack(spacing: 8) {
            Text("\(current + 1)/\(total)")
                .font(.headline)

            PageIndicatorView(totalPages: total, currentIndex: current)

            HStack(spacing: 12) {
                Button("-") {
                    current = max(current - 1, 0)
                }
                .buttonStyle(.bordered)

                Button("+") {
                    current = min(current + 1, total - 1)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        Group {
            PageIndicatorView(totalPages: 1, currentIndex: 0)

            PageIndicatorView(totalPages: 2, currentIndex: 0)
            PageIndicatorView(totalPages: 2, currentIndex: 1)

            PageIndicatorView(totalPages: 3, currentIndex: 0)
            PageIndicatorView(totalPages: 3, currentIndex: 1)
            PageIndicatorView(totalPages: 3, currentIndex: 2)
        }

        Group {
            PageIndicatorView(totalPages: 4, currentIndex: 0)
            PageIndicatorView(totalPages: 4, currentIndex: 1)
            PageIndicatorView(totalPages: 4, currentIndex: 2)
            PageIndicatorView(totalPages: 4, currentIndex: 3)
        }

        Group {
            PageIndicatorView(totalPages: 5, currentIndex: 0)
            PageIndicatorView(totalPages: 5, currentIndex: 2)
            PageIndicatorView(totalPages: 5, currentIndex: 4)
        }

        InteractiveDemo()
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
#endif
