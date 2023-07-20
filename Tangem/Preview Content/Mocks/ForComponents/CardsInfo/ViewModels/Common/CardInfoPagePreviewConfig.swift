//
//  CardInfoPagePreviewConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardInfoPagePreviewConfig: Identifiable {
    let id = UUID()
    let initiallySelectedIndex: Int
    let hasPullToRefresh: Bool
}
