//
//  SensitiveText.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SensitiveText: View {
    @ObservedObject private var sensitiveTextVisibilityViewModel: SensitiveTextVisibilityViewModel = .shared
    private let textType: TextType

    init(_ textType: TextType) {
        self.textType = textType
    }

    init(_ text: String) {
        textType = .string(text)
    }

    init(_ text: AttributedString) {
        textType = .attributed(text)
    }

    init(builder: @escaping (String) -> String, sensitive: String) {
        textType = .builder(builder: builder, sensitive: sensitive)
    }

    var body: some View {
        switch textType {
        case .string(let string):
            Text(sensitiveTextVisibilityViewModel.isHidden ? Constants.maskedBalanceString : string)
        case .attributed(let string):
            Text(sensitiveTextVisibilityViewModel.isHidden ? AttributedString(Constants.maskedBalanceString) : string)
        case .builder(let builder, let sensitive):
            Text(builder(sensitiveTextVisibilityViewModel.isHidden ? Constants.maskedBalanceString : sensitive))
        }
    }
}

extension SensitiveText {
    enum TextType {
        case string(String)
        case attributed(AttributedString)
        case builder(builder: (String) -> String, sensitive: String)
    }
}

// MARK: - SensitiveText.TextType + Hashable

extension SensitiveText.TextType: Hashable {
    static func == (lhs: SensitiveText.TextType, rhs: SensitiveText.TextType) -> Bool {
        switch (lhs, rhs) {
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.attributed(let lhs), .attributed(let rhs)):
            return lhs == rhs
        case (.builder(let lhsBuilder, let lhs), .builder(let rhsBbuilder, let rhs)):
            return lhsBuilder(lhs) == rhsBbuilder(rhs)
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
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

extension SensitiveText {
    enum Constants {
        static let maskedBalanceString: String = "\u{2217}\u{2217}\u{2217}"
    }
}
