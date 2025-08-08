//
//  UIFonts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

public enum UIFonts {
    public enum Regular {
        public static let body = UIFont.preferredFont(forTextStyle: .body)
        public static let callout = UIFont.preferredFont(forTextStyle: .callout)
        public static let subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
        public static let caption1 = UIFont.preferredFont(forTextStyle: .caption1)
        public static let caption2 = UIFont.preferredFont(forTextStyle: .caption2)
    }

    public enum Bold {
        public static var callout: UIFont {
            let font = UIFont.systemFont(ofSize: 16, weight: .medium)
            let metrics = UIFontMetrics(forTextStyle: .callout)
            return metrics.scaledFont(for: font)
        }

        public static let title1 = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title1).pointSize, weight: .bold)
        public static let headline = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)
        public static let footnote = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .semibold)
    }
}
