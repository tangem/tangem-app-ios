//
//  TwoLineRowWithIcon.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct TwoLineRowWithIcon<
    Icon: View,
    PrimaryLeading: View,
    PrimaryTrailing: View,
    SecondaryLeading: View,
    SecondaryTrailing: View
>: View {
    private let icon: Icon
    private let primaryLeadingView: PrimaryLeading
    private let primaryTrailingView: PrimaryTrailing
    private let secondaryLeadingView: SecondaryLeading
    private let secondaryTrailingView: SecondaryTrailing

    private var linesSpacing: CGFloat = 4

    // MARK: - State

    @State private var textBlockWidth: CGFloat = .zero

    public init(
        icon: () -> Icon,
        @ViewBuilder primaryLeadingView: () -> PrimaryLeading,
        @ViewBuilder primaryTrailingView: () -> PrimaryTrailing,
        @ViewBuilder secondaryLeadingView: () -> SecondaryLeading,
        @ViewBuilder secondaryTrailingView: () -> SecondaryTrailing,
    ) {
        self.icon = icon()
        self.primaryLeadingView = primaryLeadingView()
        self.primaryTrailingView = primaryTrailingView()
        self.secondaryLeadingView = secondaryLeadingView()
        self.secondaryTrailingView = secondaryTrailingView()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            icon

            VStack(spacing: linesSpacing) {
                firstLine
                secondLine
            }
            .readGeometry(\.size.width, bindTo: $textBlockWidth)
        }
    }

    private var firstLine: some View {
        HStack(spacing: 8) {
            primaryLeadingView
                .frame(minWidth: 0.3 * textBlockWidth, maxWidth: .infinity, alignment: .leading)

            primaryTrailingView
                .frame(alignment: .trailing)
        }
    }

    private var secondLine: some View {
        HStack(spacing: 12) {
            secondaryLeadingView
                .frame(minWidth: 0.32 * textBlockWidth, maxWidth: .infinity, alignment: .leading)

            secondaryTrailingView
                .frame(alignment: .trailing)
        }
    }
}

public extension TwoLineRowWithIcon {
    enum SecondLineMode {
        case hidden
        case exists(
            secondaryLeadingView: () -> SecondaryLeading,
            secondaryTrailingView: () -> SecondaryTrailing,
        )
    }
}

// MARK: - Setupable

extension TwoLineRowWithIcon: Setupable {
    public func linesSpacing(_ linesSpacing: CGFloat) -> Self {
        map { $0.linesSpacing = linesSpacing }
    }
}
