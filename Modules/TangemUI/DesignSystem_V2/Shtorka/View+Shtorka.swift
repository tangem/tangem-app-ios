//
//  View+Shtorka.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension View {
    func shtorka<Content: View>(
        isPresented: Binding<Bool>,
        size: Binding<ShtorkaSize>,
        detents: ShtorkaDetents = ShtorkaDetents(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ShtorkaModifier(isPresented: isPresented, size: size, detents: detents, sheetContent: content))
    }
}

private struct ShtorkaModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var size: ShtorkaSize
    let detents: ShtorkaDetents
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    .presentationDetents(detents.all, selection: detentSelection)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: detents.medium))
                    .interactiveDismissDisabled()
                    .modifier(ShtorkaBackgroundModifier(size: size))
            }
    }

    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: { detents.detent(for: size) },
            set: { detents.size(for: $0).map { size = $0 } }
        )
    }
}

private struct ShtorkaBackgroundModifier: ViewModifier {
    let size: ShtorkaSize

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            filled(content)
        } else {
            filled(content)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(Constants.legacyCornerRadius)
        }
    }

    private func filled(_ content: Content) -> some View {
        content.background(fill.ignoresSafeArea())
    }

    private var fill: Color {
        size == .full ? DesignSystem.Color.bgPrimary : .clear
    }
}

// MARK: - Constants

private extension ShtorkaBackgroundModifier {
    enum Constants {
        static let legacyCornerRadius: CGFloat = 40
    }
}
