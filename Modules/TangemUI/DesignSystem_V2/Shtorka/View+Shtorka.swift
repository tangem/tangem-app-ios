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
        state: ShtorkaState,
        detents: ShtorkaDetents = ShtorkaDetents(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ShtorkaModifier(isPresented: isPresented, state: state, detents: detents, sheetContent: content))
    }
}

private struct ShtorkaModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let state: ShtorkaState
    let detents: ShtorkaDetents
    @ViewBuilder let sheetContent: () -> SheetContent

    @StateObject private var progressTracker = ShtorkaProgressTracker()
    @State private var revealedHeight = ShtorkaMetrics.minimumRevealedHeight
    /// The state is a plain object, so the body renders from this mirror of `state.size`.
    @State private var size: ShtorkaSize = .collapsed

    func body(content: Content) -> some View {
        content
            .environment(\.shtorka, state)
            .sheet(isPresented: $isPresented) {
                revealedContent
                    .environment(\.shtorka, state)
                    .presentationDetents([detents.collapsed, detents.medium, detents.full], selection: detentSelection)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: detents.medium))
                    .interactiveDismissDisabled()
                    .modifier(ShtorkaBackgroundModifier(size: size))
            }
            .onReceive(state.sizePublisher) { size = $0 }
            .onChange(of: isPresented) { isPresented in
                if !isPresented {
                    progressTracker.reset()
                }
            }
    }

    private var revealedContent: some View {
        GeometryReader { proxy in
            Color.clear
                .ignoresSafeArea(.container, edges: .bottom)
                .overlay(alignment: .top) {
                    sheetContent()
                        .frame(height: revealedHeight)
                }
                .clipped()
                .onAppear { ingest(proxy) }
                .onChange(of: proxy.size.height) { _ in ingest(proxy) }
        }
    }

    /// The visible sheet height: an edge-to-edge sheet keeps the bottom safe area outside `proxy.size`.
    private func ingest(_ proxy: GeometryProxy) {
        let height = proxy.size.height + proxy.safeAreaInsets.bottom
        revealedHeight = max(revealedHeight, height)
        progressTracker.ingest(height: height, from: state)
    }

    private func detent(for size: ShtorkaSize) -> PresentationDetent {
        switch size {
        case .collapsed: detents.collapsed
        case .medium: detents.medium
        case .full: detents.full
        }
    }

    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: { detent(for: size) },
            set: { newValue in
                let newSize = ShtorkaSize.allCases.last { detent(for: $0) == newValue }
                state.size = newSize ?? state.size
            }
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
