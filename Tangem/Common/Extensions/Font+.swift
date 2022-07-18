//
//  Font+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public extension Font {
    /// weight: regular, size: 34
    static let largeTitle = Font.system(size: 34, weight: .regular)
    /// weight: regular, size: 28
    static let title1 = Font.system(size: 28, weight: .regular)
    /// weight: regular, size: 22
    static let title2 = Font.system(size: 22, weight: .regular)
    /// weight: regular, size: 20
    static let title3 = Font.system(size: 20, weight: .regular)
    /// weight: semibold, size: 17
    static let headline = Font.system(size: 17, weight: .semibold)
    /// weight: regular, size: 17
    static let body = Font.system(size: 17, weight: .regular)
    /// weight: regular, size: 16
    static let callout = Font.system(size: 16, weight: .regular)
    /// weight: regular, size: 15
    static let subheadline = Font.system(size: 15, weight: .regular)
    /// weight: regular, size: 13
    static let footnote = Font.system(size: 13, weight: .regular)
    /// weight: regular, size: 12
    static let caption1 = Font.system(size: 12, weight: .regular)
    /// weight: regular, size: 11
    static let caption2 = Font.system(size: 11, weight: .regular)
}

public extension Font {
    var medium: Font { weight(.medium) }
    var semibold: Font { weight(.semibold) }
    var bold: Font { weight(.bold) }
}
