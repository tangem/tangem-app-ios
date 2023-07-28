//
//  CardHeaderSubtitleInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CardHeaderSubtitleInfo {
    let message: String
    let formattingOption: CardHeaderSubtitleFormattingOption

    static let empty: CardHeaderSubtitleInfo = .init(message: "", formattingOption: .default)
}

enum CardHeaderSubtitleFormattingOption {
    case `default`
    case error

    var textColor: Color {
        switch self {
        case .default: return Colors.Text.tertiary
        case .error: return Colors.Text.attention
        }
    }

    var font: Font {
        Fonts.Regular.caption2
    }
}
