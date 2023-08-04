//
//  MainHeaderSubtitleInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MainHeaderSubtitleInfo {
    let message: String
    let formattingOption: MainHeaderSubtitleFormattingOption

    static let empty: MainHeaderSubtitleInfo = .init(message: "", formattingOption: .default)
}

extension MainHeaderSubtitleInfo {
    enum MainHeaderSubtitleFormattingOption {
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
}
