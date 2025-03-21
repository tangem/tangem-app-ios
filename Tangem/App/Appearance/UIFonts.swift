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
        static let body = UIFont.preferredFont(forTextStyle: .body)
        static let subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
        static let caption2 = UIFont.preferredFont(forTextStyle: .caption2)
    }

    enum Bold {
        static var callout: UIFont {
            let font = UIFont.systemFont(ofSize: 16, weight: .medium)
            let metrics = UIFontMetrics(forTextStyle: .callout)
            return metrics.scaledFont(for: font)
        }
    }
}
