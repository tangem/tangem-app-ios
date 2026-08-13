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
        TangemMessageBubble(text: model.text, onClose: model.onClose)
            .variant(variant)
            .icon(model.icon)
            .lineLimit(1)
            .contentShape(Rectangle())
            .onTapGesture { if isEnabled { model.onTap() } }
    }
}

// MARK: - Appearance

private extension TokenRowMessageBubble {
    var variant: TangemMessageBubble.Variant {
        switch model.accent {
        case .yield: return .success
        case .staking: return .info
        }
    }
}

// MARK: - Model

public extension TokenRowMessageBubble {
    typealias Accent = TokenRowAccent

    struct Model: Equatable {
        public let text: String
        public let accent: Accent
        public let icon: ImageType?
        @IgnoredEquatable
        public var onTap: () -> Void
        @IgnoredEquatable
        public var onClose: () -> Void

        public init(
            text: String,
            accent: Accent,
            icon: ImageType? = nil,
            onTap: @escaping () -> Void,
            onClose: @escaping () -> Void
        ) {
            self.text = text
            self.accent = accent
            self.icon = icon
            self.onTap = onTap
            self.onClose = onClose
        }
    }
}
