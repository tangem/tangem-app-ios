//
//  View+ShtorkaPresentation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func shtorkaCompatibleSheet<C: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> C
    ) -> some View {
        modifier(ShtorkaSheetModifier(isPresented: isPresented, presentedContent: content))
    }

    func shtorkaCompatibleSheet<Item: Identifiable, C: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> C
    ) -> some View {
        modifier(ShtorkaSheetItemModifier(item: item, presentedContent: content))
    }

    func shtorkaCompatibleFullScreenCover<C: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> C
    ) -> some View {
        modifier(ShtorkaCoverModifier(isPresented: isPresented, presentedContent: content))
    }

    func shtorkaCompatibleFullScreenCover<Item: Identifiable, C: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> C
    ) -> some View {
        modifier(ShtorkaCoverItemModifier(item: item, presentedContent: content))
    }

    func shtorkaCompatibleAlert<A: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String? = nil,
        @ViewBuilder actions: @escaping () -> A
    ) -> some View {
        modifier(ShtorkaAlertModifier(title: title, message: message, isPresented: isPresented, actions: actions))
    }

    func shtorkaCompatibleAlert<Item: Identifiable>(
        item: Binding<Item?>,
        alert: @escaping (Item) -> Alert
    ) -> some View {
        modifier(ShtorkaLegacyAlertModifier(item: item, alert: alert))
    }

    func shtorkaCompatibleConfirmationDialog<Item: Identifiable, A: View>(
        item: Binding<Item?>,
        title: @escaping (Item) -> String,
        titleVisibility: Visibility = .automatic,
        message: ((Item) -> String)? = nil,
        @ViewBuilder actions: @escaping (Item) -> A
    ) -> some View {
        modifier(
            ShtorkaDialogItemModifier(
                item: item,
                title: title,
                titleVisibility: titleVisibility,
                message: message,
                actions: actions
            )
        )
    }

    func shtorkaCompatibleConfirmationDialog<A: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        titleVisibility: Visibility = .automatic,
        message: String? = nil,
        @ViewBuilder actions: @escaping () -> A
    ) -> some View {
        modifier(
            ShtorkaDialogModifier(
                title: title,
                titleVisibility: titleVisibility,
                message: message,
                isPresented: isPresented,
                actions: actions
            )
        )
    }
}

// MARK: - Sheet

private struct ShtorkaSheetModifier<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let presentedContent: () -> C

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: nativeBinding(isPresented: $isPresented, isShtorkaActive: isShtorkaActive)) { presentedContent() }
            .onChange(of: isPresented) { syncSlot(isPresented: $0) }
    }

    /// A presenter holds one presentation at a time, and while the shtorka is up that presentation is the shtorka
    /// itself, so anything the screen underneath wants to show has to be shown by the sheet instead. The host keeps
    /// one slot per presentation kind (`sheetItem`, `coverItem`, ...), and this mirrors the modifier's binding into the
    /// sheet slot: rising hands the content over, falling releases it. Releasing checks the slot first, because a
    /// dismissal the sheet already handled echoes back through the binding after the slot is empty.
    /// The seven modifiers below follow the same shape.
    private func syncSlot(isPresented: Bool) {
        guard isShtorkaActive, let host else { return }

        if isPresented {
            host.sheetItem = makeItem()
        } else if host.sheetItem != nil {
            host.sheetItem = nil
        }
    }

    private func makeItem() -> ShtorkaPresentationHost.PresentedItem {
        ShtorkaPresentationHost.PresentedItem(
            content: { AnyView(presentedContent()) },
            onDismiss: { isPresented = false }
        )
    }
}

private struct ShtorkaSheetItemModifier<Item: Identifiable, C: View>: ViewModifier {
    @Binding var item: Item?
    let presentedContent: (Item) -> C

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .sheet(item: nativeBinding(item: $item, isShtorkaActive: isShtorkaActive)) { presentedContent($0) }
            // The closure only gets the id; the binding reads through to the source of truth, so it already holds the new item.
            .onChange(of: item?.id) { _ in syncSlot(item: item) }
    }

    private func syncSlot(item: Item?) {
        guard isShtorkaActive, let host else { return }

        if let item {
            host.sheetItem = makeItem(for: item)
        } else if host.sheetItem != nil {
            host.sheetItem = nil
        }
    }

    private func makeItem(for item: Item) -> ShtorkaPresentationHost.PresentedItem {
        ShtorkaPresentationHost.PresentedItem(
            content: { AnyView(presentedContent(item)) },
            onDismiss: { self.item = nil }
        )
    }
}

// MARK: - Full screen cover

private struct ShtorkaCoverModifier<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let presentedContent: () -> C

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: nativeBinding(isPresented: $isPresented, isShtorkaActive: isShtorkaActive)) { presentedContent() }
            .onChange(of: isPresented) { syncSlot(isPresented: $0) }
    }

    private func syncSlot(isPresented: Bool) {
        guard isShtorkaActive, let host else { return }

        if isPresented {
            host.coverItem = makeItem()
        } else if host.coverItem != nil {
            host.coverItem = nil
        }
    }

    private func makeItem() -> ShtorkaPresentationHost.PresentedItem {
        ShtorkaPresentationHost.PresentedItem(
            content: { AnyView(presentedContent()) },
            onDismiss: { isPresented = false }
        )
    }
}

private struct ShtorkaCoverItemModifier<Item: Identifiable, C: View>: ViewModifier {
    @Binding var item: Item?
    let presentedContent: (Item) -> C

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: nativeBinding(item: $item, isShtorkaActive: isShtorkaActive)) { presentedContent($0) }
            .onChange(of: item?.id) { _ in syncSlot(item: item) }
    }

    private func syncSlot(item: Item?) {
        guard isShtorkaActive, let host else { return }

        if let item {
            host.coverItem = makeItem(for: item)
        } else if host.coverItem != nil {
            host.coverItem = nil
        }
    }

    private func makeItem(for item: Item) -> ShtorkaPresentationHost.PresentedItem {
        ShtorkaPresentationHost.PresentedItem(
            content: { AnyView(presentedContent(item)) },
            onDismiss: { self.item = nil }
        )
    }
}

// MARK: - Alert

private struct ShtorkaAlertModifier<A: View>: ViewModifier {
    let title: String
    let message: String?
    @Binding var isPresented: Bool
    let actions: () -> A

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: nativeBinding(isPresented: $isPresented, isShtorkaActive: isShtorkaActive), actions: actions) {
                if let message {
                    Text(message)
                }
            }
            .onChange(of: isPresented) { syncSlot(isPresented: $0) }
    }

    private func syncSlot(isPresented: Bool) {
        guard isShtorkaActive, let host else { return }

        if isPresented {
            host.alertItem = makeItem()
        } else if host.alertItem != nil {
            host.alertItem = nil
        }
    }

    private func makeItem() -> ShtorkaPresentationHost.AlertItem {
        ShtorkaPresentationHost.AlertItem(
            title: title,
            message: message,
            actions: { AnyView(actions()) },
            onDismiss: { isPresented = false }
        )
    }
}

private struct ShtorkaLegacyAlertModifier<Item: Identifiable>: ViewModifier {
    @Binding var item: Item?
    let alert: (Item) -> Alert

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .alert(item: nativeBinding(item: $item, isShtorkaActive: isShtorkaActive)) { alert($0) }
            .onChange(of: item?.id) { _ in syncSlot(item: item) }
    }

    private func syncSlot(item: Item?) {
        guard isShtorkaActive, let host else { return }

        if let item {
            host.legacyAlertItem = makeItem(for: item)
        } else if host.legacyAlertItem != nil {
            host.legacyAlertItem = nil
        }
    }

    private func makeItem(for item: Item) -> ShtorkaPresentationHost.LegacyAlertItem {
        ShtorkaPresentationHost.LegacyAlertItem(
            alert: { alert(item) },
            onDismiss: { self.item = nil }
        )
    }
}

// MARK: - Confirmation dialog

private struct ShtorkaDialogModifier<A: View>: ViewModifier {
    let title: String
    let titleVisibility: Visibility
    let message: String?
    @Binding var isPresented: Bool
    let actions: () -> A

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                title,
                isPresented: nativeBinding(isPresented: $isPresented, isShtorkaActive: isShtorkaActive),
                titleVisibility: titleVisibility,
                actions: actions
            ) {
                if let message {
                    Text(message)
                }
            }
            .onChange(of: isPresented) { syncSlot(isPresented: $0) }
    }

    private func syncSlot(isPresented: Bool) {
        guard isShtorkaActive, let host else { return }

        if isPresented {
            host.dialogItem = makeItem()
        } else if host.dialogItem != nil {
            host.dialogItem = nil
        }
    }

    private func makeItem() -> ShtorkaPresentationHost.DialogItem {
        ShtorkaPresentationHost.DialogItem(
            title: title,
            titleVisibility: titleVisibility,
            message: message,
            actions: { AnyView(actions()) },
            onDismiss: { isPresented = false }
        )
    }
}

private struct ShtorkaDialogItemModifier<Item: Identifiable, A: View>: ViewModifier {
    @Binding var item: Item?
    let title: (Item) -> String
    let titleVisibility: Visibility
    let message: ((Item) -> String)?
    let actions: (Item) -> A

    @Environment(\.shtorkaPresentationHost) private var host
    @Environment(\.isShtorkaActive) private var isShtorkaActive

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                item.map(title) ?? "",
                isPresented: nativeBinding(isPresented: presented, isShtorkaActive: isShtorkaActive),
                titleVisibility: titleVisibility,
                presenting: item,
                actions: actions,
                message: { item in
                    if let message {
                        Text(message(item))
                    }
                }
            )
            .onChange(of: item?.id) { _ in syncSlot(item: item) }
    }

    private var presented: Binding<Bool> {
        Binding(
            get: { item != nil },
            set: { isPresented in
                if !isPresented {
                    item = nil
                }
            }
        )
    }

    private func syncSlot(item: Item?) {
        guard isShtorkaActive, let host else { return }

        if let item {
            host.dialogItem = makeItem(for: item)
        } else if host.dialogItem != nil {
            host.dialogItem = nil
        }
    }

    private func makeItem(for item: Item) -> ShtorkaPresentationHost.DialogItem {
        ShtorkaPresentationHost.DialogItem(
            title: title(item),
            titleVisibility: titleVisibility,
            message: message?(item),
            actions: { AnyView(actions(item)) },
            onDismiss: { self.item = nil }
        )
    }
}

// MARK: - Native fallback

private func nativeBinding<Item>(item: Binding<Item?>, isShtorkaActive: Bool) -> Binding<Item?> {
    Binding(
        get: { isShtorkaActive ? nil : item.wrappedValue },
        set: { newValue in
            if newValue == nil {
                item.wrappedValue = nil
            }
        }
    )
}

private func nativeBinding(isPresented: Binding<Bool>, isShtorkaActive: Bool) -> Binding<Bool> {
    Binding(
        get: { isPresented.wrappedValue && !isShtorkaActive },
        set: { newValue in
            if !newValue {
                isPresented.wrappedValue = false
            }
        }
    )
}
