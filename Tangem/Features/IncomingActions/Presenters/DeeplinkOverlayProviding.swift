//
//  DeeplinkOverlayProviding.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

/// A destination that has a screen of its own to show over whatever the user is looking at. Conformances live
/// next to the screens they build, in `Presenters/Overlays`, so what a link is parsed into stays free of views.
@MainActor
protocol DeeplinkOverlayProviding {
    /// `nil` — this link has no screen here after all: it names a wallet the device doesn't have, a feature
    /// that is off, or a destination someone else shows.
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult?
}

/// What an overlay needs from the presenter that will host it: the identity of the link it answers, the
/// factory its coordinator is built by, and the way back — closing what is up.
@MainActor
struct DeeplinkOverlayContext {
    /// The link's identity: the same link asked for twice is the same overlay.
    let id: String
    let coordinatorFactory: MainCoordinatorChildFactory

    private let presentAction: (OverlayView) -> Void
    private let dismissAction: () -> Void

    init(
        id: String,
        coordinatorFactory: MainCoordinatorChildFactory,
        present: @escaping (OverlayView) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.id = id
        self.coordinatorFactory = coordinatorFactory
        presentAction = present
        dismissAction = dismiss
    }

    /// The usual way up.
    func sheet(_ view: some View, id: String? = nil) -> OverlayView {
        OverlayView(id: id ?? self.id, view: view, style: .sheet)
    }

    /// Over everything, for a screen that owns the whole flow it starts. `animated: false` pops it in at once,
    /// for a view that does its own fade.
    func cover(_ view: some View, animated: Bool = true) -> OverlayView {
        OverlayView(id: id, view: view, style: .fullScreenCover, animated: animated)
    }

    /// Puts an overlay up in place of the one that is there — a screen a flow asks for on its way out. A flow
    /// reports from wherever it happens to be, so the way onto the main actor is inside rather than expected
    /// of the caller; the same goes for `dismiss`.
    func present(_ overlay: OverlayView) {
        presentAction(overlay)
    }

    /// Closes the overlay that is up. A coordinator reports its way out through this.
    func dismiss() {
        dismissAction()
    }

    /// The navigation stack the deeplink screens share — the one that carries the close button. A flow that
    /// brings its own navigation, or its own way out, is shown as it is.
    func embedInNavigationStack(@ViewBuilder _ view: () -> some View) -> AnyView {
        AnyView(
            NavigationStack {
                view()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(Localization.commonClose) { dismiss() }
                                .foregroundColor(Colors.Text.primary1)
                        }
                    }
            }
        )
    }
}
