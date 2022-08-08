//
//  ChangeObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct ChangeObserver<V: Equatable>: ViewModifier {
    private typealias Action = (V) -> Void

    private let newValue: V
    private let newAction: Action

    @State private var state: (V, Action)?

    init(newValue: V, action: @escaping (V) -> Void) {
        self.newValue = newValue
        self.newAction = action
    }

    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            assertionFailure("Please don't use this ViewModifer directly and use the `onChange(of:perform:)` modifier instead.")
        }
        return content
            .onAppear()
            .onReceive(Just(newValue)) { newValue in
                if let (currentValue, action) = state, newValue != currentValue {
                    action(newValue)
                }
                state = (newValue, newAction)
            }
    }
}
