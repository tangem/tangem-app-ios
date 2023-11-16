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
    }

    enum Bold {
        static let footnote: UIFont = FeatureProvider.isAvailable(.dynamicFonts) ? .preferredFont(forTextStyle: .footnote) : .systemFont(ofSize: 13, weight: .semibold)
    }
}
