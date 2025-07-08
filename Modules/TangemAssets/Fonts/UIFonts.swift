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
        public static let largeTitle = UIFont.preferredFont(forTextStyle: .largeTitle)
        public static let title1 = UIFont.preferredFont(forTextStyle: .title1)
        public static let title2 = UIFont.preferredFont(forTextStyle: .title2)
        public static let title3 = UIFont.preferredFont(forTextStyle: .title3)
        public static let headline = UIFont.preferredFont(forTextStyle: .headline)
        public static let body = UIFont.preferredFont(forTextStyle: .body)
        public static let callout = UIFont.preferredFont(forTextStyle: .callout)
        public static let subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
        public static let footnote = UIFont.preferredFont(forTextStyle: .footnote)
        public static let caption1 = UIFont.preferredFont(forTextStyle: .caption1)
        public static let caption2 = UIFont.preferredFont(forTextStyle: .caption2)
    }

    public enum Bold {
        public static let largeTitle = UIFont.systemFont(ofSize: Regular.largeTitle.pointSize, weight: .bold)
        public static let title1 = UIFont.systemFont(ofSize: Regular.title1.pointSize, weight: .bold)
        public static let title2 = UIFont.systemFont(ofSize: Regular.title2.pointSize, weight: .bold)
        public static let title3 = UIFont.systemFont(ofSize: Regular.title3.pointSize, weight: .bold)
        public static let headline = UIFont.systemFont(ofSize: Regular.headline.pointSize)
        public static let body = UIFont.systemFont(ofSize: Regular.body.pointSize, weight: .semibold)
        public static let callout = UIFont.systemFont(ofSize: Regular.callout.pointSize, weight: .medium)
        public static let subheadline = UIFont.systemFont(ofSize: Regular.subheadline.pointSize, weight: .medium)
        public static let footnote = UIFont.systemFont(ofSize: Regular.footnote.pointSize, weight: .semibold)
        public static let caption1 = UIFont.systemFont(ofSize: Regular.caption1.pointSize, weight: .medium)
        public static let caption2 = UIFont.systemFont(ofSize: Regular.caption2.pointSize, weight: .semibold)
    }

    public enum RegularStatic {
        public static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .regular)
        public static let title1 = UIFont.systemFont(ofSize: 28, weight: .semibold)
        public static let title2 = UIFont.systemFont(ofSize: 22, weight: .regular)
        public static let title3 = UIFont.systemFont(ofSize: 20, weight: .regular)
        public static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        public static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
        public static let callout = UIFont.systemFont(ofSize: 16, weight: .regular)
        public static let subheadline = UIFont.systemFont(ofSize: 15, weight: .regular)
        public static let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)
        public static let caption1 = UIFont.systemFont(ofSize: 12, weight: .regular)
        public static let caption2 = UIFont.systemFont(ofSize: 11, weight: .regular)
    }

    public enum BoldStatic {
        public static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold)
        public static let title1 = UIFont.systemFont(ofSize: 28, weight: .bold)
        public static let title2 = UIFont.systemFont(ofSize: 22, weight: .bold)
        public static let title3 = UIFont.systemFont(ofSize: 20, weight: .semibold)
        public static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        public static let body = UIFont.systemFont(ofSize: 17, weight: .semibold)
        public static let callout = UIFont.systemFont(ofSize: 16, weight: .medium)
        public static let subheadline = UIFont.systemFont(ofSize: 15, weight: .medium)
        public static let footnote = UIFont.systemFont(ofSize: 13, weight: .semibold)
        public static let caption1 = UIFont.systemFont(ofSize: 12, weight: .medium)
        public static let caption2 = UIFont.systemFont(ofSize: 11, weight: .semibold)
    }
}
