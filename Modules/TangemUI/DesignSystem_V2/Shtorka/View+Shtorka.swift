//
//  View+Shtorka.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets

public extension View {
    func shtorka<Content: View>(
        isPresented: Binding<Bool>,
        size: Binding<ShtorkaSize>,
        detents: ShtorkaDetents = ShtorkaDetents(),
        expansionProgress: AnyPublisher<CGFloat, Never> = Empty().eraseToAnyPublisher(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(
            ShtorkaModifier(
                isPresented: isPresented,
                size: size,
                detents: detents,
                expansionProgress: expansionProgress,
                sheetContent: content
            )
        )
    }
}

private struct ShtorkaModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var size: ShtorkaSize
    let detents: ShtorkaDetents
    let expansionProgress: AnyPublisher<CGFloat, Never>
    @ViewBuilder let sheetContent: () -> SheetContent

    @StateObject private var presentationHost = ShtorkaPresentationHost()

    func body(content: Content) -> some View {
        content
            .environment(\.shtorkaPresentationHost, presentationHost)
            .environment(\.isShtorkaActive, isPresented)
            .sheet(isPresented: $isPresented) {
                sheetContent()
                    .modifier(ShtorkaScrollTouchModifier())
                    .shtorkaPresentationHost(presentationHost)
                    .environment(\.shtorkaPresentationHost, presentationHost)
                    .environment(\.isShtorkaActive, isPresented)
                    .presentationDetents(detents.all, selection: detentSelection)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: detents.medium))
                    .interactiveDismissDisabled()
                    .modifier(ShtorkaBackgroundModifier(size: size, expansionProgress: expansionProgress))
            }
            .onChange(of: isPresented) { isPresented in
                if !isPresented {
                    presentationHost.dismissAll()
                }
            }
    }

    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: { detents.detent(for: size) },
            set: { detents.size(for: $0).map { size = $0 } }
        )
    }
}

private struct ShtorkaScrollTouchModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else if #available(iOS 18.0, *) {
            // iOS 18 can release a button as a tap after the sheet takes over its drag; a simultaneous tap recognizer restores the cancellation.
            content.simultaneousGesture(TapGesture())
        } else {
            content
        }
    }
}

private struct ShtorkaBackgroundModifier: ViewModifier {
    let size: ShtorkaSize
    let expansionProgress: AnyPublisher<CGFloat, Never>

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            filled(content)
        } else {
            filled(content)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(Constants.cornerRadius)
        }
    }

    private func filled(_ content: Content) -> some View {
        content
            .containerCornerRadius(Constants.cornerRadius)
            .background {
                ShtorkaSurface(
                    tintsMaterial: true,
                    opacity: size == .full ? 1 : 0,
                    expansionProgress: expansionProgress
                )
                .ignoresSafeArea()
            }
    }
}

// MARK: - Constants

private extension ShtorkaBackgroundModifier {
    enum Constants {
        static let cornerRadius: CGFloat = 40
    }
}
