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
    static let tangem = TangemFont.self
}

public enum TangemFont {
    // Regular
    public static let largeTitle: Font = .largeTitle
    public static let title2: Font = .title2
    public static let title3: Font = .title3
    public static let body: Font = .body
    public static let callout: Font = .callout
    public static let subheadline: Font = .subheadline
    public static let footnote: Font = .footnote
    public static let caption1: Font = .caption
    public static let caption2: Font = .caption2

    // Medium
    public static let calloutMedium: Font = .callout.weight(.medium)
    public static let subheadlineMedium: Font = .subheadline.weight(.medium)
    public static let caption1Medium: Font = .caption.weight(.medium)

    // Semibold
    public static let headline: Font = .headline.weight(.semibold)
    public static let title1: Font = .title.weight(.semibold)
    public static let title3Semibold: Font = .title3.weight(.semibold)
    public static let bodySemibold: Font = .body.weight(.semibold)
    public static let footnoteSemibold: Font = .footnote.weight(.semibold)
    public static let caption2Semibold: Font = .caption2.weight(.semibold)

    // Bold
    public static let largeTitleBold: Font = .largeTitle.weight(.bold)
    public static let title1Bold: Font = .title.weight(.bold)
    public static let title2Bold: Font = .title2.weight(.bold)
}
