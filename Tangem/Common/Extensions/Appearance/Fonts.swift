//
//  Fonts.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public enum Fonts {
    /// weight: regular, size: 34
    case largeTitle
    /// weight: regular, size: 28
    case title1
    /// weight: regular, size: 22
    case title2
    /// weight: regular, size: 20
    case title3
    /// weight: semibold, size: 17
    case headline
    /// weight: regular, size: 17
    case body
    /// weight: regular, size: 16
    case callout
    /// weight: regular, size: 15
    case subheadline
    /// weight: regular, size: 13
    case footnote
    /// weight: regular, size: 12
    case caption1
    /// weight: regular, size: 11
    case caption2
    
    var font: Font {
        switch self {
        case .largeTitle:
            return Font.system(size: 34, weight: .regular)
        case .title1:
            return Font.system(size: 28, weight: .regular)
        case .title2:
            return Font.system(size: 22, weight: .regular)
        case .title3:
            return Font.system(size: 20, weight: .regular)
        case .headline:
            return Font.system(size: 17, weight: .semibold)
        case .body:
            return Font.system(size: 17, weight: .regular)
        case .callout:
            return Font.system(size: 16, weight: .regular)
        case .subheadline:
            return Font.system(size: 15, weight: .regular)
        case .footnote:
            return Font.system(size: 13, weight: .regular)
        case .caption1:
            return Font.system(size: 12, weight: .regular)
        case .caption2:
            return Font.system(size: 11, weight: .regular)
        }
    }
}

public extension Font {
    var medium: Font { weight(.medium) }
    var semibold: Font { weight(.semibold) }
    var bold: Font { weight(.bold) }
}
