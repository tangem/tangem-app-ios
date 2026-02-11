//
//  StringPasteButton.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct StringPasteButton: View {
    let style: Style
    let action: (String) -> Void

    @State private var isDisabled: Bool = false

    var body: some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).receive(on: DispatchQueue.main)) { _ in
                isDisabled = !UIPasteboard.general.hasStrings
            }
            .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification).receive(on: DispatchQueue.main)) { _ in
                isDisabled = !UIPasteboard.general.hasStrings
            }
            .onAppear {
                isDisabled = !UIPasteboard.general.hasStrings
            }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .native:
            native
        case .custom:
            custom
        }
    }

    private var native: some View {
        PasteButton(payloadType: String.self) { strings in
            if let string = strings.first {
                // We receive the value on the non-GUI thread
                DispatchQueue.main.async { action(string) }
            }
        }
        .tint(.black)
        .labelStyle(.titleOnly)
        .buttonBorderShape(.capsule)
        .fixedSize()
        .disableAnimations()
    }

    private var custom: some View {
        CapsuleButton(title: Localization.commonPaste) {
            if let string = UIPasteboard.general.string {
                action(string)
            }
        }
        .disabled(isDisabled)
    }
}

extension StringPasteButton {
    enum Style {
        case native
        case custom
    }
}
