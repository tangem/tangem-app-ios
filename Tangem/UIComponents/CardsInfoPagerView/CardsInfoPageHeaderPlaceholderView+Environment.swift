//
//  CardsInfoPageHeaderPlaceholderView+Environment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

enum CardsInfoPageHeaderPlaceholderHeightEnvironmentKey: EnvironmentKey {
    static var defaultValue: CGFloat { .zero }
}

extension EnvironmentValues {
    var cardsInfoPageHeaderPlaceholderHeight: CGFloat {
        get { self[CardsInfoPageHeaderPlaceholderHeightEnvironmentKey.self] }
        set { self[CardsInfoPageHeaderPlaceholderHeightEnvironmentKey.self] = newValue }
    }
}
