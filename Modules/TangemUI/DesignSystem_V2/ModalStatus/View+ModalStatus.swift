//
//  View+ModalStatus.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func modalStatus<Content: View>(
        isPresented: Binding<Bool>,
        size: ModalSize = .flexible,
        dragIndicator: Visibility = .visible,
        onClose: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modal(
            isPresented: isPresented,
            size: size,
            contentLayout: .intrinsic,
            dragIndicator: dragIndicator,
            navigation: .closeButton(onClose: onClose),
            onDismiss: onDismiss,
            content: content
        )
    }

    func modalStatus<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        size: ModalSize = .flexible,
        dragIndicator: Visibility = .visible,
        onClose: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modal(
            item: item,
            size: { _ in size },
            contentLayout: .intrinsic,
            dragIndicator: dragIndicator,
            navigation: .closeButton(onClose: onClose),
            onDismiss: onDismiss,
            content: content
        )
    }
}
