//
//  CloseButton.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

public struct CloseButton: View {
    private let dismiss: () -> Void

    public init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    public var body: some View {
        Button(
            action: dismiss,
            label: {
                Text(Localization.commonClose)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            }
        )
    }
}
