//
//  MarketsPortfolioTokenBalanceState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct SwiftUI.Color
import TangemUI
import TangemAssets

enum MarketsPortfolioTokenBalanceState {
    typealias Text = SensitiveText.TextType

    case loaded(Text)
    case loadingCached(Text)
    case loading
    case failed(Text, Icon? = nil)

    struct Icon {
        let type: ImageType
        let color: Color
        let location: Location

        enum Location {
            case leading
            case trailing
        }
    }
}
