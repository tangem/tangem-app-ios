//
//  TypographyStyle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

enum TypographyStyle {
    /// weight: regular/bold, size: 34
    case largeTitle(_ styleType: StyleType = .default)

    /// weight: regular/bold, size: 28
    case title1(_ styleType: StyleType = .default)

    /// weight: regular/bold, size: 22
    case title2(_ styleType: StyleType = .default)

    /// weight: regular/semibold, size: 20
    case title3(_ styleType: StyleType = .default)

    /// weight: semibold, size: 17
    case headline

    /// weight: regular/semibold, size: 17
    case body(_ styleType: StyleType = .default)

    /// weight: regular/medium, size: 16
    case callout(_ styleType: StyleType = .default)

    /// weight: regular/medium, size: 15
    case subheadline(_ styleType: StyleType = .default)

    /// weight: regular/semibold, size: 13
    case footnote(_ styleType: StyleType = .default)

    /// weight: regular/medium, size: 12
    case caption1(_ styleType: StyleType = .default)

    /// weight: regular/semibold, size: 11
    case caption2(_ styleType: StyleType = .default)

    var font: Font {
        switch self {
        case .largeTitle:
            return .system(size: 34, weight: weight)
        case .title1:
            return  .system(size: 28, weight: weight)
        case .title2:
            return   .system(size: 22, weight: weight)
        case .title3:
            return .system(size: 20, weight: weight)
        case .headline:
            return .system(size: 17, weight: weight)
        case .body:
            return .system(size: 17, weight: weight)
        case .callout:
            return .system(size: 16, weight: weight)
        case .subheadline:
            return .system(size: 15, weight: weight)
        case .footnote:
            return .system(size: 13, weight: weight)
        case .caption1:
            return .system(size: 12, weight: weight)
        case .caption2:
            return .system(size: 11, weight: weight)
        }
    }

    var weight: Font.Weight {
        switch self {
        case let .largeTitle(style):
            return style == .default ? .regular : .bold
        case let .title1(style):
            return style == .default ? .regular : .bold
        case let .title2(style):
            return style == .default ? .regular : .bold
        case let .title3(style):
            return style == .default ? .regular : .semibold
        case .headline:
            return .semibold
        case let .body(style):
            return style == .default ? .regular : .semibold
        case let .callout(style):
            return style == .default ? .regular : .medium
        case let .subheadline(style):
            return style == .default ? .regular : .semibold
        case let .footnote(style):
            return style == .default ? .regular : .semibold
        case let .caption1(style):
            return style == .default ? .regular : .medium
        case let .caption2(style):
            return style == .default ? .regular : .semibold
        }
    }
}

extension TypographyStyle {
    enum StyleType {
        case `default`
        case accent
    }
}
