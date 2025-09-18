//
//  Font+.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Tangem fonts

public extension Font {
    enum Tangem {}
}

public extension Font.Tangem {
    // Regular
    static let largeTitle: Font = .largeTitle
    static let title2: Font = .title2
    static let title3: Font = .title3
    static let body: Font = .body
    static let callout: Font = .callout
    static let subheadline: Font = .subheadline
    static let footnote: Font = .footnote
    static let caption1: Font = .caption
    static let caption2: Font = .caption2

    // Medium
    static let calloutMedium: Font = .callout.weight(.medium)
    static let subheadlineMedium: Font = .subheadline.weight(.medium)
    static let caption1Medium: Font = .caption.weight(.medium)

    // Semibold
    static let headline: Font = .headline.weight(.semibold)
    static let title1: Font = .title.weight(.semibold)
    static let title3Semibold: Font = .title3.weight(.semibold)
    static let bodySemibold: Font = .body.weight(.semibold)
    static let footnoteSemibold: Font = .footnote.weight(.semibold)
    static let caption2Semibold: Font = .caption2.weight(.semibold)

    // Bold
    static let largeTitleBold: Font = .largeTitle.weight(.bold)
    static let title1Bold: Font = .title.weight(.bold)
    static let title2Bold: Font = .title2.weight(.bold)
}
