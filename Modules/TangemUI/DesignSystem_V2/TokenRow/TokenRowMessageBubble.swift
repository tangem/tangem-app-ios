//
//  TokenRowMessageBubble.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

public struct TokenRowMessageBubble: View {
    private let model: Model

    @Environment(\.isEnabled) private var isEnabled

    public init(_ model: Model) {
        self.model = model
    }

    public var body: some View {
        TangemMessageBubble(text: model.text)
            .variant(model.variant)
            .icon(model.icon)
            .trailingAccessory(model.trailingAccessory)
            .lineLimit(1)
            .contentShape(Rectangle())
            .onTapGesture { if isEnabled { model.onTap() } }
    }
}

// MARK: - Model

public extension TokenRowMessageBubble {
    typealias Variant = TangemMessageBubble.Variant
    typealias TrailingAccessory = TangemMessageBubble.TrailingAccessory

    struct Model: Equatable {
        public let text: String
        public let variant: Variant
        public let icon: ImageType?
        public let trailingAccessory: TrailingAccessory?
        @IgnoredEquatable
        public var onTap: () -> Void

        public init(
            text: String,
            variant: Variant,
            icon: ImageType? = nil,
            trailingAccessory: TrailingAccessory?,
            onTap: @escaping () -> Void
        ) {
            self.text = text
            self.variant = variant
            self.icon = icon
            self.trailingAccessory = trailingAccessory
            self.onTap = onTap
        }
    }
}
