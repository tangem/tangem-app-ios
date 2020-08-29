//
//  KeyboardAdaptive.swift
//  KeyboardAvoidanceSwiftUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Vadim Bulavin. All rights reserved.
//

import SwiftUI
import Combine

/// Note that the `KeyboardAdaptive` modifier wraps your view in a `GeometryReader`, 
/// which attempts to fill all the available space, potentially increasing content view size.
struct KeyboardAdaptive: ViewModifier {
    @State private var bottomPadding: CGFloat = 0
    @State private var animationDuration: Double = 0
    
    func body(content: Content) -> some View {
       // GeometryReader { geometry in
            content
                .padding(.bottom, self.bottomPadding)
                .onReceive(Publishers.keyboardInfo) { keyboardHeight, animationDuration in
                   // let keyboardTop = geometry.frame(in: .global).height - keyboardHeight
                   // let focusedTextInputBottom = UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0
                    let bottomSafeAreaInset = keyboardHeight > 0 ? UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 : 0
                    self.animationDuration = animationDuration
                    self.bottomPadding = keyboardHeight - bottomSafeAreaInset// max(0, focusedTextInputBottom - keyboardTop - geometry.safeAreaInsets.bottom)
            }
            .animation( Animation.easeOut(duration: animationDuration))
       // }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}
