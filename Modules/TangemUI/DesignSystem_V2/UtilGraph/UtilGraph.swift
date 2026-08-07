//
//  UtilGraph.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct UtilGraph: View, Setupable {
    private let values: [Double]
    private var direction: Direction = .neutral
    private var isLoading: Bool = false

    public init(values: [Double]) {
        self.values = values
    }

    public var body: some View {
        if isLoading {
            Shimmer()
                .variant(.custom(height: Metrics.loadingHeight, cornerRadius: Metrics.loadingCornerRadius))
                .frame(maxHeight: .infinity, alignment: .center)
        } else {
            curve
        }
    }

    private var curve: some View {
        GeometryReader { geometry in
            linePath(for: geometry.size)
                .stroke(direction.lineColor, style: StrokeStyle(lineWidth: Metrics.lineWidth, lineCap: .round))
                .background {
                    LinearGradient(
                        colors: [direction.lineColor.opacity(Metrics.fillOpacity), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(fillPath(for: geometry.size))
                }
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private func linePath(for size: CGSize) -> Path {
        guard
            values.count >= Metrics.minimumPointCount,
            let minimum = values.min(),
            let maximum = values.max()
        else {
            return Path()
        }

        let inset = Metrics.lineWidth / 2
        let drawableWidth = size.width - Metrics.lineWidth
        let drawableHeight = size.height - Metrics.lineWidth
        let step = drawableWidth / Double(values.count - 1)
        let range = maximum - minimum
        let points = values.enumerated().map { index, value in
            CGPoint(
                x: inset + step * Double(index),
                y: inset + (range == 0 ? drawableHeight / 2 : (maximum - value) / range * drawableHeight)
            )
        }

        return Path { path in
            path.move(to: points[0])

            for index in points.indices {
                if index == points.count - 1 {
                    path.addLine(to: points[index])
                } else if index == 0 {
                    path.addLine(to: midPoint(points[index], points[index + 1]))
                } else {
                    path.addQuadCurve(to: midPoint(points[index], points[index + 1]), control: points[index])
                }
            }
        }
    }

    private func fillPath(for size: CGSize) -> Path {
        var path = linePath(for: size)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        return path
    }

    private func midPoint(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2)
    }
}

// MARK: - Setupable

public extension UtilGraph {
    enum Direction: Hashable, Sendable, CaseIterable {
        case positive
        case neutral
        case negative
    }

    func direction(_ direction: Direction) -> Self {
        map { $0.direction = direction }
    }

    func isLoading(_ isLoading: Bool = true) -> Self {
        map { $0.isLoading = isLoading }
    }
}

// MARK: - Palette

private extension UtilGraph.Direction {
    var lineColor: Color {
        switch self {
        case .positive:
            DesignSystem.Color.borderAccentBlue

        case .neutral:
            DesignSystem.Color.borderAccentNeutral

        case .negative:
            DesignSystem.Color.borderAccentRed
        }
    }
}

// MARK: - Metrics

private extension UtilGraph {
    enum Metrics {
        static let lineWidth: CGFloat = 1
        static let fillOpacity: CGFloat = 0.2
        static let loadingHeight: CGFloat = 16
        /// A graph placeholder is not text, so it keeps a rectangle's radius instead of a capsule's.
        static let loadingCornerRadius: CGFloat = 4
        static let minimumPointCount = 2
    }
}
