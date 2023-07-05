//
//  CardsInfoPagerScrollViewConnectable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
protocol CardsInfoPagerScrollViewConnectable {
    associatedtype PlaceholderView: View

    var contentOffset: Binding<CGPoint> { get }
    var placeholderView: PlaceholderView { get }
}
