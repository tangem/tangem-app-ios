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
        contentLayout: @escaping (Item) -> ModalContentLayout = { _ in .scrollable },
        dragIndicator: Visibility = .visible,
        navigation: @escaping (Item) -> ModalNavigation?,
        @ViewBuilder header: @escaping (Item) -> Header,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        let modal = ItemModal(
            size: size,
            contentLayout: contentLayout,
            dragIndicator: dragIndicator,
            navigation: navigation,
            header: header,
            bodyContent: content
        )

        return modifier(ItemModalPresentationModifier(item: item, onDismiss: onDismiss, sheetContent: modal.modal(for:)))
    }

    func modal<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        size: @escaping (Item) -> ModalSize = { _ in .flexible },
        contentLayout: @escaping (Item) -> ModalContentLayout = { _ in .scrollable },
        dragIndicator: Visibility = .visible,
        navigation: @escaping (Item) -> ModalNavigation?,
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

    func modal<Item: Identifiable & ObservableObject, Header: View, Content: View>(
        item: Binding<Item?>,
        size: @escaping (Item) -> ModalSize = { _ in .flexible },
        contentLayout: @escaping (Item) -> ModalContentLayout = { _ in .scrollable },
        dragIndicator: Visibility = .visible,
        navigation: @escaping (Item) -> ModalNavigation?,
        @ViewBuilder header: @escaping (Item) -> Header,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        let modal = ItemModal(
            size: size,
            contentLayout: contentLayout,
            dragIndicator: dragIndicator,
            navigation: navigation,
            header: header,
            bodyContent: content
        )

        return modifier(ItemModalPresentationModifier(item: item, onDismiss: onDismiss) { item in
            ObservedItem(item: item, content: modal.modal(for:))
        })
    }

    func modal<Item: Identifiable & ObservableObject, Content: View>(
        item: Binding<Item?>,
        size: @escaping (Item) -> ModalSize = { _ in .flexible },
        contentLayout: @escaping (Item) -> ModalContentLayout = { _ in .scrollable },
        dragIndicator: Visibility = .visible,
        navigation: @escaping (Item) -> ModalNavigation?,
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
        modal(
            item: item,
            size: size,
            contentLayout: { _ in contentLayout },
            dragIndicator: dragIndicator,
            navigation: { _ in navigation },
            header: header,
            onDismiss: onDismiss,
            content: content
        )
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
            contentLayout: { _ in contentLayout },
            dragIndicator: dragIndicator,
            navigation: { _ in navigation },
            header: { _ in EmptyView() },
            onDismiss: onDismiss,
            content: content
        )
    }

    func shtorkaCompatibleModal<Item: Identifiable, Header: View, Content: View>(
        item: Binding<Item?>,
        size: @escaping (Item) -> ModalSize = { _ in .flexible },
        contentLayout: ModalContentLayout = .scrollable,
        dragIndicator: Visibility = .visible,
        navigation: ModalNavigation? = nil,
        @ViewBuilder header: @escaping (Item) -> Header,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(ShtorkaCompatibleItemModalModifier(
            item: item,
            size: size,
            contentLayout: contentLayout,
            dragIndicator: dragIndicator,
            navigation: navigation,
            header: header,
            bodyContent: content
        ))
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
            PresentedModal(
                size: size,
                contentLayout: contentLayout,
                dragIndicator: dragIndicator,
                navigation: navigation,
                dynamicTypeSize: dynamicTypeSize,
                header: header,
                bodyContent: bodyContent
            )
            .softTopScrollEdgeEffect()
        }
    }
}

private struct ItemModalPresentationModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let sheetContent: (Item) -> SheetContent

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.sheet(item: $item, onDismiss: onDismiss) { item in
            sheetContent(item)
                .dynamicTypeSize(dynamicTypeSize)
                .modifier(SheetScrollTouchModifier())
                .softTopScrollEdgeEffect()
        }
    }
}

private struct ObservedItem<Item: ObservableObject, Content: View>: View {
    @ObservedObject var item: Item
    let content: (Item) -> Content

    var body: some View {
        content(item)
    }
}

private struct ItemModal<Item, Header: View, BodyContent: View> {
    let size: (Item) -> ModalSize
    let contentLayout: (Item) -> ModalContentLayout
    let dragIndicator: Visibility
    let navigation: (Item) -> ModalNavigation?
    let header: (Item) -> Header
    let bodyContent: (Item) -> BodyContent

    func modal(for item: Item) -> Modal<Header, BodyContent> {
        Modal(
            size: size(item),
            contentLayout: contentLayout(item),
            dragIndicator: dragIndicator,
            navigation: navigation(item),
            header: { header(item) },
            content: { bodyContent(item) }
        )
    }
}

private struct ShtorkaCompatibleItemModalModifier<Item: Identifiable, Header: View, BodyContent: View>: ViewModifier {
    @Binding var item: Item?
    let size: (Item) -> ModalSize
    let contentLayout: ModalContentLayout
    let dragIndicator: Visibility
    let navigation: ModalNavigation?
    let header: (Item) -> Header
    let bodyContent: (Item) -> BodyContent

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.shtorkaCompatibleSheet(item: $item) { item in
            PresentedModal(
                size: size(item),
                contentLayout: contentLayout,
                dragIndicator: dragIndicator,
                navigation: navigation,
                dynamicTypeSize: dynamicTypeSize,
                header: { header(item) },
                bodyContent: { bodyContent(item) }
            )
        }
    }
}

private struct PresentedModal<Header: View, BodyContent: View>: View {
    let size: ModalSize
    let contentLayout: ModalContentLayout
    let dragIndicator: Visibility
    let navigation: ModalNavigation?
    let dynamicTypeSize: DynamicTypeSize
    let header: () -> Header
    let bodyContent: () -> BodyContent

    var body: some View {
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
