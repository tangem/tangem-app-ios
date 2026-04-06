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
    enum Tangem {
        public enum Caption11 {}
        public enum Caption12 {}
        public enum Caption13 {}
        public enum Subheadline {}
        public enum Body14 {}
        public enum Body15 {}
        public enum Body16 {}
        public enum Heading17 {}
        public enum Heading20 {}
        public enum Heading22 {}
        public enum Heading28 {}
        public enum Heading34 {}
        public enum Custom {}
    }
}

// MARK: - Caption11

public extension Font.Tangem.Caption11 {
    static let regular: Font = .caption2.weight(.regular)
    static let semibold: Font = .caption2.weight(.semibold)
}

// MARK: - Caption12

public extension Font.Tangem.Caption12 {
    static let regular: Font = .caption.weight(.regular)
    static let semibold: Font = .caption.weight(.medium)
}

// MARK: - Caption13

public extension Font.Tangem.Caption13 {
    static let regular: Font = .footnote.weight(.regular)
    static let semibold: Font = .footnote.weight(.semibold)
}

// MARK: - Subheadline

public extension Font.Tangem.Subheadline {
    static let regular: Font = .subheadline.weight(.regular)
    static let medium: Font = .subheadline.weight(.medium)
}

// MARK: - Body14

public extension Font.Tangem.Body14 {
    static let regular: Font = .subheadline.weight(.medium)
}

// MARK: - Body15

public extension Font.Tangem.Body15 {
    static let regular: Font = .subheadline.weight(.regular)
    static let semibold: Font = .subheadline.weight(.medium)
}

// MARK: - Body16

public extension Font.Tangem.Body16 {
    static let regular: Font = .callout.weight(.regular)
    static let semibold: Font = .callout.weight(.semibold)
    static let medium: Font = .callout.weight(.medium)
}

// MARK: - Heading17

public extension Font.Tangem.Heading17 {
    static let regular: Font = .body.weight(.regular)
    static let semibold: Font = .body.weight(.semibold)
}

// MARK: - Heading20

public extension Font.Tangem.Heading20 {
    static let regular: Font = .title3.weight(.regular)
    static let semibold: Font = .title3.weight(.semibold)
}

// MARK: - Heading22

public extension Font.Tangem.Heading22 {
    static let regular: Font = .title2.weight(.regular)
    static let bold: Font = .title2.weight(.bold)
}

// MARK: - Heading28

public extension Font.Tangem.Heading28 {
    static let regular: Font = .title.weight(.semibold)
    static let bold: Font = .title.weight(.bold)
}

// MARK: - Heading34

public extension Font.Tangem.Heading34 {
    static let regular: Font = .largeTitle.weight(.regular)
    static let bold: Font = .largeTitle.weight(.bold)
}

// MARK: - Custom

public extension Font.Tangem.Custom {
    static let titleRegular44: Font = .system(size: 44, weight: .semibold, design: .default)
}
