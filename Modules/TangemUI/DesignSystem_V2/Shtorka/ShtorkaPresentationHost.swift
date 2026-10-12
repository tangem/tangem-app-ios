//
//  ShtorkaPresentationHost.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension EnvironmentValues {
    /// The host that presents on behalf of the shtorka's content, so a `shtorkaCompatible*` modifier at any depth can
    /// hand it a sheet, a cover, an alert or a dialog. A plain `@Environment` value on purpose: the modifiers only push
    /// into it, and the one view that renders from it, the sheet, observes it through `@ObservedObject`.
    @Entry var shtorkaPresentationHost: ShtorkaPresentationHost?

    /// Whether the enclosing shtorka is on screen. While it is, the content presents through the host instead of natively.
    @Entry var isShtorkaActive = false
}

final class ShtorkaPresentationHost: ObservableObject {
    @Published var sheetItem: PresentedItem?
    @Published var coverItem: PresentedItem?
    @Published var alertItem: AlertItem?
    @Published var legacyAlertItem: LegacyAlertItem?
    @Published var dialogItem: DialogItem?

    func dismissAll() {
        let dismissals = [sheetItem?.onDismiss, coverItem?.onDismiss, alertItem?.onDismiss, legacyAlertItem?.onDismiss, dialogItem?.onDismiss]

        sheetItem = nil
        coverItem = nil
        alertItem = nil
        legacyAlertItem = nil
        dialogItem = nil

        dismissals.forEach { $0?() }
    }
}

// MARK: - Items

extension ShtorkaPresentationHost {
    struct PresentedItem: Identifiable {
        let id = UUID()
        let content: () -> AnyView
        let onDismiss: () -> Void
    }

    /// Backs `.alert(_:isPresented:presenting:actions:message:)`: a title, a message and action buttons built as views.
    struct AlertItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String?
        let actions: () -> AnyView
        let onDismiss: () -> Void
    }

    /// Backs `.alert(item:)` with a ready-made `SwiftUI.Alert`, the form the app's `AlertBinder` produces. Neither converts
    /// into the other: `Alert` is opaque, and the view-based form has no `Alert.Button`s to build one from.
    struct LegacyAlertItem: Identifiable {
        let id = UUID()
        let alert: () -> Alert
        let onDismiss: () -> Void
    }

    struct DialogItem: Identifiable {
        let id = UUID()
        let title: String
        let titleVisibility: Visibility
        let message: String?
        let actions: () -> AnyView
        let onDismiss: () -> Void
    }
}

// MARK: - Host modifier

extension View {
    func shtorkaPresentationHost(_ host: ShtorkaPresentationHost) -> some View {
        modifier(ShtorkaPresentationHostModifier(host: host))
    }
}

private struct ShtorkaPresentationHostModifier: ViewModifier {
    @ObservedObject var host: ShtorkaPresentationHost

    func body(content: Content) -> some View {
        content
            .sheet(item: sheetBinding) { $0.content() }
            .fullScreenCover(item: coverBinding) { $0.content() }
            .alert(
                host.alertItem?.title ?? "",
                isPresented: alertBinding,
                presenting: host.alertItem,
                actions: { $0.actions() },
                message: { message($0.message) }
            )
            .alert(item: legacyAlertBinding) { $0.alert() }
            .confirmationDialog(
                host.dialogItem?.title ?? "",
                isPresented: dialogBinding,
                titleVisibility: host.dialogItem?.titleVisibility ?? .automatic,
                presenting: host.dialogItem,
                actions: { $0.actions() },
                message: { message($0.message) }
            )
    }

    @ViewBuilder
    private func message(_ text: String?) -> some View {
        if let text {
            Text(text)
        }
    }

    private var sheetBinding: Binding<ShtorkaPresentationHost.PresentedItem?> {
        Binding(
            get: { host.sheetItem },
            set: { newValue in
                guard newValue == nil, let item = host.sheetItem else { return }

                host.sheetItem = nil
                item.onDismiss()
            }
        )
    }

    private var coverBinding: Binding<ShtorkaPresentationHost.PresentedItem?> {
        Binding(
            get: { host.coverItem },
            set: { newValue in
                guard newValue == nil, let item = host.coverItem else { return }

                host.coverItem = nil
                item.onDismiss()
            }
        )
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { host.alertItem != nil },
            set: { isPresented in
                guard !isPresented, let item = host.alertItem else { return }

                host.alertItem = nil
                item.onDismiss()
            }
        )
    }

    private var legacyAlertBinding: Binding<ShtorkaPresentationHost.LegacyAlertItem?> {
        Binding(
            get: { host.legacyAlertItem },
            set: { newValue in
                guard newValue == nil, let item = host.legacyAlertItem else { return }

                host.legacyAlertItem = nil
                item.onDismiss()
            }
        )
    }

    private var dialogBinding: Binding<Bool> {
        Binding(
            get: { host.dialogItem != nil },
            set: { isPresented in
                guard !isPresented, let item = host.dialogItem else { return }

                host.dialogItem = nil
                item.onDismiss()
            }
        )
    }
}
