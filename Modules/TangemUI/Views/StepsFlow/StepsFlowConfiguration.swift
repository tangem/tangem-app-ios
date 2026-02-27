//
//  StepsFlowConfiguration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StepsFlowConfiguration {
    let hasProgressBar: Bool
    let navigationBarHeight: CGFloat
    let progressBarHeight: CGFloat
    let progressBarPadding: CGFloat

    public init(
        hasProgressBar: Bool,
        navigationBarHeight: CGFloat,
        progressBarHeight: CGFloat,
        progressBarPadding: CGFloat
    ) {
        self.hasProgressBar = hasProgressBar
        self.navigationBarHeight = navigationBarHeight
        self.progressBarHeight = progressBarHeight
        self.progressBarPadding = progressBarPadding
    }
}
