//
//  SensitiveText.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public struct SensitiveText: View {
    @ObservedObject private var visibilityState: SensitiveTextVisibilityState = .shared
    private let textType: TextType

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
        switch textType {
        case .string(let string):
            Text(visibilityState.isHidden ? Constants.maskedBalanceString : string)
        case .attributed(let string):
            Text(visibilityState.isHidden ? AttributedString(Constants.maskedBalanceString) : string)
                .monospacedDigit()
        case .builder(let builder, let sensitive):
            Text(builder(visibilityState.isHidden ? Constants.maskedBalanceString : sensitive))
        }
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

// MARK: - Constants

public extension SensitiveText {
    enum Constants {
        public static let maskedBalanceString: String = "\u{2217}\u{2217}\u{2217}"
    }
}
