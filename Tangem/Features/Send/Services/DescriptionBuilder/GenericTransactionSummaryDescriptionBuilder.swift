//
//  GenericTransactionSummaryDescriptionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

protocol GenericTransactionSummaryDescriptionBuilder {}

extension GenericTransactionSummaryDescriptionBuilder {
    func makeAttributedString(_ string: String, richTexts: [String] = []) -> AttributedString {
        // Remove the rich text
        let description = string.replacingOccurrences(of: "*", with: "")
        var attributedString = AttributedString(description)

        attributedString.font = Fonts.Regular.caption1
        attributedString.foregroundColor = Colors.Text.tertiary
        richTexts.forEach { rich in
            if let range = attributedString.range(of: rich) {
                attributedString[range].font = Fonts.Bold.caption1
            }
        }

        return attributedString
    }
}
