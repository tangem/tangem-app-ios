//
//  OverlayContentStateObserverViewModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

extension View {
    /// - Warning: This method maintains strong reference to the given `observer` closure.
    @ViewBuilder
    func onOverlayContentStateChange(
        _ observer: @escaping OverlayContentStateObserver.Observer
    ) -> some View {
        modifier(OverlayContentStateObserverViewModifier(observer: observer))
    }
}

// MARK: - Private implementation

private struct OverlayContentStateObserverViewModifier: ViewModifier {
    private let observer: OverlayContentStateObserver.Observer

    @State private var token = UUID()

    @available(iOS, deprecated: 17.0, message: "Not needed if `View.onChange(of:initial:_:)` is available (iOS 17+)")
    @State private var isAppeared = false

    @Environment(\.overlayContentStateObserver) private var overlayContentStateObserver

    init(observer: @escaping BottomScrollableSheetStateObserver) {
        self.observer = observer
    }

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: token, initial: true) { oldValue, newValue in
                    updateObserver(oldToken: oldValue, newToken: newValue)
                }
        } else {
            content
                .onChange(of: token) { [oldValue = token] newValue in
                    updateObserver(oldToken: oldValue, newToken: newValue)
                }
                .onAppear {
                    guard !isAppeared else {
                        return
                    }

                    /// Prevents warnings like "Modifying state during view update, this will cause undefined behavior."
                    DispatchQueue.main.async {
                        isAppeared = true
                    }

                    updateObserver(oldToken: token, newToken: token)
                }
        }
    }

    private func updateObserver(oldToken: UUID, newToken: UUID) {
        overlayContentStateObserver.removeObserver(forToken: oldToken)
        overlayContentStateObserver.addObserver(observer, forToken: newToken)
    }
}
