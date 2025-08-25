//
//  HideKeyboardButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct HideKeyboardButton: View {
    private let focused: FocusState<Bool>.Binding

    public init(focused: FocusState<Bool>.Binding) {
        self.focused = focused
    }

    public var body: some View {
        Button {
            focused.wrappedValue = false
        } label: {
            Assets.hideKeyboard.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.primary1)
        }
    }
}
