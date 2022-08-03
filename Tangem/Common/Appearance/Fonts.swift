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
    static func largeTitle(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 34, weight: weight)
    }

    /// weight: regular, size: 28
    static func title1(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 28, weight: weight)
    }

    /// weight: regular, size: 22
    static func title2(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 22, weight: weight)
    }

    /// weight: regular, size: 20
    static func title3(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 20, weight: weight)
    }

    /// weight: semibold, size: 17
    static func headline(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 17, weight: weight)
    }

    /// weight: regular, size: 17
    static func body(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 17, weight: weight)
    }

    /// weight: regular, size: 16
    static func callout(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 16, weight: weight)
    }

    /// weight: regular, size: 15
    static func subheadline(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight)
    }

    /// weight: regular, size: 13
    static func footnote(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight)
    }

    /// weight: regular, size: 12
    static func caption1(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 12, weight: weight)
    }

    /// weight: regular, size: 11
    static func caption2(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 11, weight: weight)
    }
}
