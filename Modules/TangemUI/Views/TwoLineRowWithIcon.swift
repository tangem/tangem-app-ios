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

            VStack(spacing: 4) {
                firstLine
                secondLine
            }
            .readGeometry(\.size.width, bindTo: $textBlockWidth)
        }
    }

    private var firstLine: some View {
        HStack(spacing: 6) {
            primaryLeadingView
                .frame(minWidth: 0.3 * textBlockWidth, alignment: .leading)

            Spacer(minLength: 8)

            primaryTrailingView
        }
    }

    private var secondLine: some View {
        HStack(spacing: 0) {
            secondaryLeadingView
                .frame(minWidth: 0.32 * textBlockWidth, alignment: .leading)

            Spacer(minLength: 12)

            secondaryTrailingView
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
