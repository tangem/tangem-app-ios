//
//  UtilPriceChange.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct UtilPriceChange: View, Setupable {
    private let value: String
    private let direction: Direction
    private var accessibilityIdentifier: String?
    private var accessibilityLabel: String?

    @ScaledMetric(relativeTo: .caption) private var markerSize: CGFloat = Metrics.markerSize

    public init(value: String, direction: Direction) {
        self.value = value
        self.direction = direction
    }

    public var body: some View {
        HStack(spacing: Metrics.markerSpacing) {
            marker

            Text(value)
                .style(DesignSystem.Font.captionMediumToken, color: direction.textColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var marker: some View {
        direction.marker.image
            .renderingMode(.template)
            .resizable()
            .frame(width: markerSize, height: markerSize)
            .foregroundStyle(direction.iconColor)
            .accessibilityHidden(true)
    }
}

// MARK: - Setupable

public extension UtilPriceChange {
    func accessibilityIdentifier(_ accessibilityIdentifier: String) -> Self {
        map { $0.accessibilityIdentifier = accessibilityIdentifier }
    }

    func accessibilityLabel(_ accessibilityLabel: String?) -> Self {
        map { $0.accessibilityLabel = accessibilityLabel }
    }
}

// MARK: - Public Type

public extension UtilPriceChange {
    enum Direction: Hashable, Sendable, CaseIterable {
        case positive
        case neutral
        case negative
    }
}

// MARK: - Palette

private extension UtilPriceChange.Direction {
    var marker: ImageType {
        switch self {
        case .positive:
            DesignSystem.Icons.TriangleUp.regular12

        case .neutral:
            DesignSystem.Icons.Dot.filled12

        case .negative:
            DesignSystem.Icons.TriangleDown.regular12
        }
    }

    var textColor: Color {
        switch self {
        case .positive:
            DesignSystem.Color.textAccentBlue

        case .neutral:
            DesignSystem.Color.textSecondary

        case .negative:
            DesignSystem.Color.textAccentRed
        }
    }

    var iconColor: Color {
        switch self {
        case .positive:
            DesignSystem.Color.iconAccentBlue

        case .neutral:
            DesignSystem.Color.iconSecondary

        case .negative:
            DesignSystem.Color.iconAccentRed
        }
    }
}

// MARK: - Metrics

private extension UtilPriceChange {
    enum Metrics {
        static let markerSize: CGFloat = 12
        static let markerSpacing: CGFloat = 2
    }
}
