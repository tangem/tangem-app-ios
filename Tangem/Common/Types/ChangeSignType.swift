//
//  ChangeSignType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

enum ChangeSignType: Int, Hashable {
    case positive
    case negative

    init(from value: Decimal) {
        if value >= 0 {
            self = .positive
        } else {
            self = .negative
        }
    }

    var imageType: ImageType? {
        switch self {
        case .positive:
            return Assets.quotePositive
        case .negative:
            return Assets.quoteNegative
        }
    }

    var textColor: Color {
        switch self {
        case .positive:
            return Colors.Text.accent
        case .negative:
            return Colors.Text.warning
        }
    }
}
