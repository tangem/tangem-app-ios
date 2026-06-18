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
    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    @ViewBuilder
    func onOverlayContentStateChange(
        overlayContentStateObserver: OverlayContentStateObserver,
        _ observer: @escaping OverlayContentStateObserver.StateObserver
    ) -> some View {
        modifier(
            OverlayContentStateObserverViewModifier(overlayContentStateObserver: overlayContentStateObserver) { stateObserver, token in
                stateObserver.addObserver(observer, forToken: token)
            }
        )
    }

    /// - Warning: This method maintains a strong reference to the given `observer` closure.
    @ViewBuilder
    func onOverlayContentProgressChange(
        overlayContentStateObserver: OverlayContentStateObserver,
        _ observer: @escaping OverlayContentStateObserver.ProgressObserver
    ) -> some View {
        modifier(
            OverlayContentStateObserverViewModifier(overlayContentStateObserver: overlayContentStateObserver) { stateObserver, token in
                stateObserver.addObserver(observer, forToken: token)
            }
        )
    }
}

// MARK: - Private implementation

private struct OverlayContentStateObserverViewModifier: ViewModifier {
    typealias Selector = (_ stateObserver: OverlayContentStateObserver, _ token: UUID) -> Void

    private weak var overlayContentStateObserver: OverlayContentStateObserver?
    private let selector: Selector

    @StateObject private var lifecycle = ObserverLifecycle()

    init(overlayContentStateObserver: OverlayContentStateObserver, selector: @escaping Selector) {
        self.overlayContentStateObserver = overlayContentStateObserver
        self.selector = selector
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !lifecycle.isRegistered, let overlayContentStateObserver else {
                    return
                }

                lifecycle.isRegistered = true
                selector(overlayContentStateObserver, lifecycle.token)
                lifecycle.onDeinit = { [weak overlayContentStateObserver, token = lifecycle.token] in
                    overlayContentStateObserver?.removeObserver(forToken: token)
                }
            }
    }
}

// MARK: - Auxiliary types

private final class ObserverLifecycle: ObservableObject {
    let token = UUID()
    var isRegistered = false
    var onDeinit: (() -> Void)?

    deinit {
        // `deinit` of a `@StateObject` runs when the view's identity leaves the hierarchy for good,
        // unlike `onDisappear`, which also fires when the view is temporarily covered
        if let onDeinit {
            DispatchQueue.main.async(execute: onDeinit)
        }
    }
}
