//
//  View+KeyboardFrame.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func keyboardHeight(bindTo binding: Binding<CGFloat>) -> some View {
        let frameBinding = Binding<CGRect>(
            get: {
                CGRect(
                    origin: CGPoint.zero,
                    size: CGSize(width: CGFloat.zero, height: binding.wrappedValue)
                )
            },
            set: { newValue in
                binding.wrappedValue = newValue.height
            }
        )

        return keyboardFrame(bindTo: frameBinding)
    }

    func keyboardFrame(bindTo binding: Binding<CGRect>) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard
                let userInfo = notification.userInfo,
                let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                return
            }

            binding.wrappedValue = frame
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            binding.wrappedValue = CGRect.zero
        }
    }
}
