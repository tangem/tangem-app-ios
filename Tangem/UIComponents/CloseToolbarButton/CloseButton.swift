//
//  CloseButton.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct CloseButton: View {
    let dismiss: () -> Void

    var body: some View {
        Button(
            action: dismiss,
            label: {
                Text(Localization.commonClose)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            }
        )
    }
}
