//
//  StepsFlowConfiguration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StepsFlowConfiguration {
    public let hasProgressBar: Bool
    public let navigationBarHeight: CGFloat
    public let progressBarHeight: CGFloat
    public let progressBarPadding: CGFloat

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
