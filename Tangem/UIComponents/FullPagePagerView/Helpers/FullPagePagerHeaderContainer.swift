//
//  FullPagePagerHeaderContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemFoundation
import TangemUI

struct FullPagePagerHeaderContainer<Content: View>: View {
    @State private var heightRatio: CGFloat?

    let elasticContainerModel: TangemElasticContainerModel
    let content: Content

    /// Decreases linearly from 100% to 90% as height collapses from 100% to 50%
    private var scale: CGFloat {
        let ratio = heightRatio ?? 1.0
        return clamp(0.2 * ratio + 0.8, min: 0, max: 1)
    }

    /// Decreases linearly from 1 to 0 value as height collapses from 100% to 50%
    private var opacity: CGFloat {
        let ratio = heightRatio ?? 1.0
        return clamp(2 * ratio - 1, min: 0, max: 1)
    }

    var body: some View {
        TangemElasticContainer(
            viewModel: elasticContainerModel,
            content: content
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(.default, value: heightRatio)
        .onReceive(elasticContainerModel.heightRatioPublisher) { heightRatio = $0 }
    }
}
