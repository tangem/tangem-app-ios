//
//  BaseOneLineRowDefaultTitleView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct BaseOneLineRowDefaultTitleView: View {
    private let title: String

    init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .style(Fonts.Regular.body, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }
}
