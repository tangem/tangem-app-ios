//
//  CardsInfoPagerBottomOverlayFactoryParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CardsInfoPagerBottomOverlayFactoryParams {
    let isDraggingHorizontally: Bool
    let didScrollToBottom: Bool
    let scrollOffset: CGPoint
    let viewportSize: CGSize
    let contentSize: CGSize
    let scrollViewBottomContentInset: CGFloat
}
