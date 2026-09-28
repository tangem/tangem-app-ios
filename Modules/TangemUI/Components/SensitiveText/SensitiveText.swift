//
//  SensitiveText.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUIUtils

public struct SensitiveText: View, Setupable {
    @ObservedObject private var visibilityState: SensitiveTextVisibilityState = .shared
    private let textType: TextType
    private var strikethroughStyle: StrikethroughStyle?

    public init(_ textType: TextType) {
        self.textType = textType
    }

    public init(_ text: String) {
        textType = .string(text)
    }

    public init(_ text: AttributedString) {
        textType = .attributed(text)
    }

    public init(builder: @escaping (String) -> String, sensitive: String) {
        textType = .builder(builder: builder, sensitive: sensitive)
    }

    public var body: some View {
        text
            .strikethrough(strikethroughStyle != nil && !visibilityState.isHidden, color: strikethroughStyle?.color)
    }

    private var text: Text {
        let maskedBalanceString = visibilityState.maskedBalanceString

        switch textType {
        case .string(let string):
            return Text(visibilityState.isHidden ? maskedBalanceString : string)
        case .attributed(let string):
            return Text(visibilityState.isHidden ? string.masked(with: maskedBalanceString) : string)
                .monospacedDigit()
        case .builder(let builder, let sensitive):
            return Text(builder(visibilityState.isHidden ? maskedBalanceString : sensitive))
        }
    }
}

// MARK: - Setupable

public extension SensitiveText {
    func strikethroughWhenVisible(_ isActive: Bool = true, color: Color? = nil) -> Self {
        map { $0.strikethroughStyle = isActive ? StrikethroughStyle(color: color) : nil }
    }
}

private extension SensitiveText {
    struct StrikethroughStyle {
        let color: Color?
    }
}

// MARK: - Masking

private extension AttributedString {
    func masked(with mask: String) -> AttributedString {
        var masked = AttributedString(mask)
        if let attributes = runs.first?.attributes {
            masked.mergeAttributes(attributes)
        }
        return masked
    }
}

// MARK: - TextType

public extension SensitiveText {
    enum TextType {
        case string(String)
        case attributed(AttributedString)
        case builder(builder: (String) -> String, sensitive: String)
    }
}

// MARK: - SensitiveText.TextType + Hashable

extension SensitiveText.TextType: Hashable {
    public static func == (lhs: SensitiveText.TextType, rhs: SensitiveText.TextType) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.attributed(let lhs), .attributed(let rhs)):
            return lhs == rhs
        case (.builder(let lhsBuilder, let lhs), .builder(let rhsBuilder, let rhs)):
            return lhsBuilder(lhs) == rhsBuilder(rhs)
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .string(let string):
            hasher.combine(string)
        case .attributed(let attributedString):
            hasher.combine(attributedString)
        case .builder(let builder, let sensitive):
            hasher.combine(builder(sensitive))
        }
    }
}
