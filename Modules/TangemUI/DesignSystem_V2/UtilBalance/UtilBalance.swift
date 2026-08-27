//
//  UtilBalance.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct UtilBalance: View, Setupable {
    private let value: Value
    private var isMasked: Bool = false
    private var isUpdating: Bool = false
    private var textLineLimit: Int? = Metrics.textLineLimit
    private var accessibilityIdentifier: String?

    public init(_ value: Value) {
        self.value = value
    }

    public init(_ value: String) {
        self.init(.string(value))
    }

    public init(_ value: AttributedString) {
        self.init(.attributed(value))
    }

    public var body: some View {
        label
            .lineLimit(textLineLimit)
            .tangemShimmer()
            .environment(\.isShimmerActive, isUpdating)
            .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private var label: some View {
        switch value {
        case .string(let string):
            Text(isMasked ? Self.maskGlyph : string)

        case .attributed(let attributed):
            Text(isMasked ? attributed.masked(with: Self.maskGlyph) : attributed)
                .monospacedDigit()
        }
    }
}

// MARK: - Setupable

public extension UtilBalance {
    func masked(_ isMasked: Bool = true) -> Self {
        map { $0.isMasked = isMasked }
    }

    func updating(_ isUpdating: Bool = true) -> Self {
        map { $0.isUpdating = isUpdating }
    }

    func lineLimit(_ lineLimit: Int?) -> Self {
        map { $0.textLineLimit = lineLimit }
    }

    func accessibilityIdentifier(_ accessibilityIdentifier: String) -> Self {
        map { $0.accessibilityIdentifier = accessibilityIdentifier }
    }
}

// MARK: - Public Type

public extension UtilBalance {
    enum Value: Hashable, Sendable {
        case string(String)
        case attributed(AttributedString)
    }

    static let maskGlyph = "\u{2217}\u{2217}\u{2217}"
}

// MARK: - Masking

private extension AttributedString {
    /// Merging the first run's attributes keeps the mask in the styling the value itself carried.
    func masked(with mask: String) -> AttributedString {
        var masked = AttributedString(mask)

        if let attributes = runs.first?.attributes {
            masked.mergeAttributes(attributes)
        }

        return masked
    }
}

// MARK: - Metrics

private extension UtilBalance {
    enum Metrics {
        static let textLineLimit: Int = 1
    }
}
