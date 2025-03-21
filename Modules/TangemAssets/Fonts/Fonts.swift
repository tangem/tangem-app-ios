//
//  Fonts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public enum Fonts {
    public enum Regular {
        public static let largeTitle = Font.largeTitle
        public static let title1 = Font.title.weight(.semibold)
        public static let title2 = Font.title2
        public static let title3 = Font.title3
        public static let headline = Font.headline
        public static let body = Font.body
        public static let callout = Font.callout
        public static let subheadline = Font.subheadline
        public static let footnote = Font.footnote
        public static let caption1 = Font.caption
        public static let caption2 = Font.caption2
    }

    public enum Bold {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title1 = Font.title.weight(.bold)
        public static let title2 = Font.title2.weight(.bold)
        public static let title3 = Font.title3.weight(.bold)
        public static let headline = Font.headline
        public static let body = Font.body.weight(.semibold)
        public static let callout = Font.callout.weight(.medium)
        public static let subheadline = Font.subheadline.weight(.medium)
        public static let footnote = Font.footnote.weight(.semibold)
        public static let caption1 = Font.caption.weight(.medium)
        public static let caption2 = Font.caption2.weight(.semibold)
    }

    public enum RegularStatic {
        public static let largeTitle = Font.system(size: 34, weight: .regular)
        public static let title1 = Font.system(size: 28, weight: .semibold)
        public static let title2 = Font.system(size: 22, weight: .regular)
        public static let title3 = Font.system(size: 20, weight: .regular)
        public static let headline = Font.system(size: 17, weight: .semibold)
        public static let body = Font.system(size: 17, weight: .regular)
        public static let callout = Font.system(size: 16, weight: .regular)
        public static let subheadline = Font.system(size: 15, weight: .regular)
        public static let footnote = Font.system(size: 13, weight: .regular)
        public static let caption1 = Font.system(size: 12, weight: .regular)
        public static let caption2 = Font.system(size: 11, weight: .regular)
    }

    public enum BoldStatic {
        public static let largeTitle = Font.system(size: 34, weight: .bold)
        public static let title1 = Font.system(size: 28, weight: .bold)
        public static let title2 = Font.system(size: 22, weight: .bold)
        public static let title3 = Font.system(size: 20, weight: .semibold)
        public static let headline = Font.system(size: 17, weight: .semibold)
        public static let body = Font.system(size: 17, weight: .semibold)
        public static let callout = Font.system(size: 16, weight: .medium)
        public static let subheadline = Font.system(size: 15, weight: .medium)
        public static let footnote = Font.system(size: 13, weight: .semibold)
        public static let caption1 = Font.system(size: 12, weight: .medium)
        public static let caption2 = Font.system(size: 11, weight: .semibold)
    }
}
