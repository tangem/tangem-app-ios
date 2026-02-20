//
//  TangemElasticContainerState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemElasticContainerState: Equatable {
    case expanded
    case collapsing(Item)
    case collapsed
    case expanding(Item)

    public struct Item: Equatable {
        public let ratio: CGFloat
        let initialHeight: CGFloat

        var offset: CGFloat { ratio * initialHeight }
    }
}
