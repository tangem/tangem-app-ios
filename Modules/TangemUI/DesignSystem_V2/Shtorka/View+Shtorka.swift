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
import TangemUIUtils

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
                    .modifier(SheetScrollTouchModifier())
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

private struct ShtorkaBackgroundModifier: ViewModifier {
    let size: ShtorkaSize
    let expansionProgress: AnyPublisher<CGFloat, Never>

    @Environment(\.displayScale) private var displayScale

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            // With the system glass a sheet released on its way to full jumps back by ~20pt, so it draws its own glass.
            filled(content)
                .background { glass }
                .presentationGlassHidden()
        } else if #available(iOS 26.0, *) {
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

    @available(iOS 26.0, *)
    private var glass: some View {
        Color.clear
            .glassEffect(.regular, in: ConcentricRectangle())
            .padding(glassInset)
            .ignoresSafeArea()
    }

    /// On iOS 27 the glass outlines its edge, and the sheet clips that outline unless the glass is a pixel smaller.
    /// iOS 26 draws a bright rim there instead, which an inset would turn into a dark line.
    private var glassInset: CGFloat {
        if #available(iOS 27.0, *) {
            return 1 / displayScale
        }

        return 0
    }
}

// MARK: - Constants

private extension ShtorkaBackgroundModifier {
    enum Constants {
        static let cornerRadius: CGFloat = 40
    }
}
