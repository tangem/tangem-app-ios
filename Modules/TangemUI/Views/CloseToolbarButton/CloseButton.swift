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
import TangemUIUtils

public struct CloseButton: View {
    private let dismiss: () -> Void
    private var disabled: Bool = false

    public init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    public var body: some View {
        Button(action: dismiss) {
            Text(Localization.commonClose)
                .style(
                    Fonts.Regular.body,
                    color: disabled ? Colors.Text.disabled : Colors.Text.primary1
                )
        }
        .disabled(disabled)
    }
}

extension CloseButton: Setupable {
    func disabled(_ disabled: Bool) -> Self {
        map { $0.disabled = disabled }
    }
}
