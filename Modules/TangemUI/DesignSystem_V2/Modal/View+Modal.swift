//
//  View+Modal.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Presents a NavigationStack with the design system's native topNavigation toolbar.
    /// Omitting `onClose` uses the sheet's dismiss action.
    func modal<Header: View, Content: View>(
        isPresented: Binding<Bool>,
        size: ModalSize = .flexible,
        contentLayout: ModalContentLayout = .scrollable,
        dragIndicator: Visibility = .visible,
        navigation: ModalNavigation? = nil,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ModalPresentationModifier(
            isPresented: isPresented,
            size: size,
            contentLayout: contentLayout,
            dragIndicator: dragIndicator,
            navigation: navigation,
            onDismiss: onDismiss,
            header: header,
            bodyContent: content
        ))
    }

    func modal<Item: Identifiable, Header: View, Content: View>(
        item: Binding<Item?>,
        size: @escaping (Item) -> ModalSize = { _ in .flexible },
        contentLayout: ModalContentLayout = .scrollable,
        dragIndicator: Visibility = .visible,
        navigation: ModalNavigation? = nil,
        @ViewBuilder header: @escaping (Item) -> Header,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(ItemModalPresentationModifier(
            item: item,
            size: size,
            contentLayout: contentLayout,
            dragIndicator: dragIndicator,
            navigation: navigation,
            onDismiss: onDismiss,
            header: header,
            bodyContent: content
        ))
    }

    func modal<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        size: @escaping (Item) -> ModalSize = { _ in .flexible },
        contentLayout: ModalContentLayout = .scrollable,
        dragIndicator: Visibility = .visible,
        navigation: ModalNavigation? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modal(
            item: item,
            size: size,
            contentLayout: contentLayout,
            dragIndicator: dragIndicator,
            navigation: navigation,
            header: { _ in EmptyView() },
            onDismiss: onDismiss,
            content: content
        )
    }
}

private struct ModalPresentationModifier<Header: View, BodyContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let size: ModalSize
    let contentLayout: ModalContentLayout
    let dragIndicator: Visibility
    let navigation: ModalNavigation?
    let onDismiss: (() -> Void)?
    let header: () -> Header
    let bodyContent: () -> BodyContent

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
            Modal(
                size: size,
                contentLayout: contentLayout,
                dragIndicator: dragIndicator,
                navigation: navigation,
                header: header,
                content: bodyContent
            )
            .dynamicTypeSize(dynamicTypeSize)
            .modifier(SheetScrollTouchModifier())
        }
    }
}

private struct ItemModalPresentationModifier<Item: Identifiable, Header: View, BodyContent: View>: ViewModifier {
    @Binding var item: Item?
    let size: (Item) -> ModalSize
    let contentLayout: ModalContentLayout
    let dragIndicator: Visibility
    let navigation: ModalNavigation?
    let onDismiss: (() -> Void)?
    let header: (Item) -> Header
    let bodyContent: (Item) -> BodyContent

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.sheet(item: $item, onDismiss: onDismiss) { item in
            Modal(
                size: size(item),
                contentLayout: contentLayout,
                dragIndicator: dragIndicator,
                navigation: navigation,
                header: { header(item) },
                content: { bodyContent(item) }
            )
            .dynamicTypeSize(dynamicTypeSize)
            .modifier(SheetScrollTouchModifier())
        }
    }
}
