//
//  PKPaymentButtonRepresentable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import PassKit
import SwiftUI

struct PKPaymentButtonRepresentable: UIViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled

    var action: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> PKPaymentButton {
        context.coordinator.button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.action = action
        uiView.isEnabled = isEnabled
    }

    final class Coordinator: NSObject {
        var action: @MainActor () -> Void
        lazy var button: PKPaymentButton = {
            let button = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .automatic)
            button.addTarget(self, action: #selector(tap), for: .touchUpInside)
            return button
        }()

        init(action: @escaping @MainActor () -> Void) {
            self.action = action
        }

        @MainActor
        @objc
        private func tap() {
            action()
        }
    }
}
