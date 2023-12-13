//
//  UIFonts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

enum UIFonts {
    enum Regular {
        static let body: UIFont = FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .body) : .systemFont(ofSize: 17, weight: .regular)
        static let subheadline: UIFont = FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(.subheadline) : .systemFont(ofSize: 15, weight: .regular)

        // Can't use a constant because of dynamic fonts
        static var footnote: UIFont {
            FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .footnote) : .systemFont(ofSize: 13, weight: .regular)
        }
    }
}
