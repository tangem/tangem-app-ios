//
//  Fonts.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public enum Fonts {
    public enum Regular {
        public static let largeTitle: Font = .largeTitle
        public static let title2: Font = .title2
        public static let title3: Font = .title3
        public static let body: Font = .body
        public static let callout: Font = .callout
        public static let subheadline: Font = .subheadline
        public static let footnote: Font = .footnote
        public static let caption1: Font = .caption
        public static let caption2: Font = .caption2
    }

    public enum Medium {
        public static let callout: Font = .callout.weight(.medium)
        public static let subheadline: Font = .subheadline.weight(.medium)
        public static let caption1: Font = .caption.weight(.medium)
    }

    public enum Semibold {
        public static let headline: Font = .headline.weight(.semibold)
        public static let title1: Font = .title.weight(.semibold)
        public static let title3: Font = .title3.weight(.semibold)
        public static let body: Font = .body.weight(.semibold)
        public static let footnote: Font = .footnote.weight(.semibold)
        public static let caption2: Font = .caption2.weight(.semibold)
    }

    public enum Bold {
        public static let largeTitle: Font = .largeTitle.weight(.bold)
        public static let title1: Font = .title.weight(.bold)
        public static let title2: Font = .title2.weight(.bold)
    }
}
