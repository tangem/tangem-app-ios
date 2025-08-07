//
//  ExpressProvider+LegalText.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import TangemExpress

extension ExpressProvider {
    func legalText(branch: ExpressBranch) -> AttributedString? {
        let tos = Localization.commonTermsOfUse
        let policy = Localization.commonPrivacyPolicy

        func makeBaseAttributedString(for text: String) -> AttributedString {
            var attributedString = AttributedString(text)
            attributedString.font = Fonts.Regular.caption1
            attributedString.foregroundColor = Colors.Text.tertiary
            return attributedString
        }

        func formatLink(in attributedString: inout AttributedString, textToSearch: String, url: URL) {
            guard let range = attributedString.range(of: textToSearch) else {
                return
            }

            attributedString[range].link = url
            attributedString[range].foregroundColor = Colors.Text.accent
        }

        if let termsOfUse = termsOfUse, let privacyPolicy = privacyPolicy {
            var attributedString: AttributedString = switch branch {
            case .swap: makeBaseAttributedString(for: Localization.expressLegalTwoPlaceholders(tos, policy))
            case .onramp: makeBaseAttributedString(for: Localization.onrampLegal(tos, policy))
            }

            formatLink(in: &attributedString, textToSearch: tos, url: termsOfUse)
            formatLink(in: &attributedString, textToSearch: policy, url: privacyPolicy)
            return attributedString
        }

        if let termsOfUse = termsOfUse {
            var attributedString = makeBaseAttributedString(for: Localization.expressLegalOnePlaceholder(tos))
            formatLink(in: &attributedString, textToSearch: tos, url: termsOfUse)
            return attributedString
        }

        if let privacyPolicy = privacyPolicy {
            var attributedString = makeBaseAttributedString(for: Localization.expressLegalOnePlaceholder(policy))
            formatLink(in: &attributedString, textToSearch: policy, url: privacyPolicy)
            return attributedString
        }

        return nil
    }
}
