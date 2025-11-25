//
//  YieldInfoFooterBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import UIKit
import TangemAssets

extension YieldModuleActiveViewModel {
    struct YieldInfoFooterBuilder {
        // MARK: - Public Implementation

        func buildForHighFee(maxFeeFiat: String, minFeeFiat: String, minFeeCrypto: String) -> AttributedString {
            let formatted = format(
                firstParagraph: Localization.yieldModuleEarnSheetHighFeeDescription(maxFeeFiat),
                secondParagraph: Localization.yieldModuleFeePolicySheetMinAmountNote(minFeeFiat, minFeeCrypto)
            )

            return AttributedString(formatted)
        }

        func build(
            estimatedFeeFiat: String,
            estimatedFeeCrypto: String,
            maxFeeFiat: String,
            maxFeeCrypto: String,
            minFeeFiat: String,
            minFeeCrypto: String
        ) -> AttributedString {
            let formatted = format(
                firstParagraph: Localization.yieldModuleFeePolicySheetFeeNote(estimatedFeeFiat, estimatedFeeCrypto, maxFeeFiat, maxFeeCrypto),
                secondParagraph: Localization.yieldModuleFeePolicySheetMinAmountNote(minFeeFiat, minFeeCrypto)
            )

            return AttributedString(formatted)
        }

        // MARK: - Private Implementation

        private func format(firstParagraph: String, secondParagraph: String) -> NSAttributedString {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byCharWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: UIFonts.Regular.footnote,
                .foregroundColor: UIColor.textTertiary,
            ]

            let text = firstParagraph + "\n\n" + secondParagraph
            return NSAttributedString(string: text, attributes: attributes)
        }
    }
}
