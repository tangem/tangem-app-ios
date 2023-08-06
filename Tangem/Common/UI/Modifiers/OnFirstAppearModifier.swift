//
//  OnFirstAppearModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        return modifier(OnFirstAppearViewModifier(action: action))
    }
}

// MARK: - Private implementation

private struct OnFirstAppearViewModifier: ViewModifier {
    let action: () -> Void

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }

            hasAppeared = true
            action()
        }
    }
}
