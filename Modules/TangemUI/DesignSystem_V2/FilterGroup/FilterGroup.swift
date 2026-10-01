//
//  FilterGroup.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct FilterGroup<Content: View>: View, Setupable {
    private let content: Content

    private var variant: FilterItemVariant = .material
    private var contentPadding: CGFloat = Constants.contentPadding

    @ScaledMetric private var spacing: CGFloat = Constants.spacing

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content
            }
            .padding(.horizontal, contentPadding)
        }
        .modifier(DisableScrollClipIfAvailable())
        .environment(\.filterItemVariant, variant)
    }
}

// MARK: - Setupable

public extension FilterGroup {
    func variant(_ variant: FilterItemVariant) -> Self {
        map { $0.variant = variant }
    }

    func contentPadding(_ padding: CGFloat) -> Self {
        map { $0.contentPadding = padding }
    }
}

// MARK: - Constants

private enum Constants {
    static let spacing: CGFloat = 4
    static let contentPadding: CGFloat = 16
}

// MARK: - Variant inheritance

extension EnvironmentValues {
    @Entry var filterItemVariant: FilterItemVariant = .material
}
