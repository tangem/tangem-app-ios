//
//  CloseTextButton.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils

public struct CloseTextButton: View {
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(Localization.commonClose)
                .style(Fonts.Regular.body, color: isEnabled ? Colors.Text.primary1 : Colors.Text.disabled)
        }
    }
}
