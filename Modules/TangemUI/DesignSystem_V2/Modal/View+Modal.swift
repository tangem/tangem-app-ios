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
    func modal<Content: View, Footer: View>(
        isPresented: Binding<Bool>,
        size: ModalSize = .flexible,
        contentLayout: ModalContentLayout = .scrollable,
        title: String,
        subtitle: String? = nil,
        leading: TopNavigation.LeadingPolicy = .none,
        actions: TopNavigation.Actions? = nil,
        onClose: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) -> some View {
        modifier(ModalPresentationModifier(
            isPresented: isPresented,
            size: size,
            contentLayout: contentLayout,
            navigation: ModalNavigation(title: title, subtitle: subtitle, leading: leading, actions: actions, onClose: onClose),
            onDismiss: onDismiss,
            header: { EmptyView() },
            bodyContent: content,
            footer: footer
        ))
    }

    func modal<Content: View, Footer: View>(
        isPresented: Binding<Bool>,
        size: ModalSize = .flexible,
        contentLayout: ModalContentLayout = .scrollable,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) -> some View {
        modal(
            isPresented: isPresented,
            size: size,
            contentLayout: contentLayout,
            onDismiss: onDismiss,
            header: { EmptyView() },
            content: content,
            footer: footer
        )
    }

    /// A required header prevents its trailing closure from binding to the optional onDismiss callback.
    func modal<Header: View, Content: View, Footer: View>(
        isPresented: Binding<Bool>,
        size: ModalSize = .flexible,
        contentLayout: ModalContentLayout = .scrollable,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) -> some View {
        modifier(ModalPresentationModifier(
            isPresented: isPresented,
            size: size,
            contentLayout: contentLayout,
            navigation: nil,
            onDismiss: onDismiss,
            header: header,
            bodyContent: content,
            footer: footer
        ))
    }
}

private struct ModalPresentationModifier<Header: View, BodyContent: View, Footer: View>: ViewModifier {
    @Binding var isPresented: Bool
    let size: ModalSize
    let contentLayout: ModalContentLayout
    let navigation: ModalNavigation?
    let onDismiss: (() -> Void)?
    let header: () -> Header
    let bodyContent: () -> BodyContent
    let footer: () -> Footer

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
            Modal(size: size, contentLayout: contentLayout, navigation: navigation, header: header, content: bodyContent, footer: footer)
                .dynamicTypeSize(dynamicTypeSize)
                .modifier(SheetScrollTouchModifier())
        }
    }
}
