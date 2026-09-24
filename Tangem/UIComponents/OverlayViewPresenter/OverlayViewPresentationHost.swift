//
//  OverlayViewPresentationHost.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

/// Puts on screen what the presenter holds, and takes it off when the presenter lets it go.
///
/// The screen is presented by whoever is on top of the app rather than by its root, which shows one thing at a
/// time: a screen the root put up would wait for whatever the user has open to be closed first. Presenting from
/// the screen the user actually sees is also what gives it the usual look of a sheet — the card behind it steps
/// back and dims.
@MainActor
final class OverlayViewPresentationHost {
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    private let viewModel: OverlayViewPresenterViewModel
    private let sheetRegistry: FloatingSheetRegistry

    private var presented: (overlay: OverlayView, viewController: UIViewController)?
    private var bag: Set<AnyCancellable> = []

    init(viewModel: OverlayViewPresenterViewModel, sheetRegistry: FloatingSheetRegistry) {
        self.viewModel = viewModel
        self.sheetRegistry = sheetRegistry

        bind()
    }
}

// MARK: - Bind

private extension OverlayViewPresentationHost {
    func bind() {
        // Without dropping the first value: a link that arrives before the scene is set up has already put its
        // screen in the presenter, and nobody would show it.
        viewModel
            .$presentedOverlay
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { host, overlay in
                host.handle(overlay)
            }
            .store(in: &bag)
    }
}

// MARK: - Presentation

private extension OverlayViewPresentationHost {
    func handle(_ overlay: OverlayView?) {
        guard let overlay else {
            dismiss()
            return
        }

        guard presented != nil else {
            present(overlay)
            return
        }

        // A presentation started while the previous screen is still closing is dropped, so the newer screen
        // waits for the older one to be gone. By then it may have been replaced or closed in turn, and what
        // the presenter holds is what the user asked for last.
        dismiss { [weak self] in
            guard let self, viewModel.presentedOverlay?.id == overlay.id else {
                return
            }

            present(overlay)
        }
    }

    func present(_ overlay: OverlayView) {
        // Presented from outside the app's own hierarchy, so what it would have inherited there is handed to it.
        let rootView = overlay.view
            .accentColor(Colors.Text.primary1)
            .environment(\.floatingSheetRegistry, sheetRegistry)
            .environment(\.mainWindowSize, UIApplication.mainWindow?.screen.bounds.size ?? .zero)

        let viewController = OverlayHostingController(rootView: rootView)
        viewController.modalPresentationStyle = Self.presentationStyle(for: overlay)

        if viewController.modalPresentationStyle == .overFullScreen {
            viewController.view.backgroundColor = .clear
        }

        // A screen can go without the presenter asking for it: the user swipes it away, or the screen it was
        // shown from is closed and takes it along. Either way the presenter has to stop holding it.
        viewController.didDisappear = { [weak self, weak viewController] in
            guard let self, presented?.viewController === viewController else {
                return
            }

            presented = nil
            viewModel.dismiss()
        }

        presented = (overlay, viewController)

        presentWhenTopIsFree(viewController, for: overlay)
    }

    /// Shows the screen as soon as the one on top is done animating: a presentation started meanwhile is dropped
    /// by UIKit. The wait is long enough for the screen to be replaced by a newer one, and then this one is
    /// abandoned — the controller it was waiting for is nobody's any more. The controller identifies it rather
    /// than the overlay's id, which a screen asked for twice shares with the one that was dropped.
    func presentWhenTopIsFree(_ viewController: UIViewController, for overlay: OverlayView) {
        guard presented?.viewController === viewController, let top = UIApplication.topViewController else {
            return
        }

        guard !top.isBeingPresented, !top.isBeingDismissed, !isShtorkaComingUp(over: top) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.presentationRetryDelay) { [weak self] in
                self?.presentWhenTopIsFree(viewController, for: overlay)
            }
            return
        }

        top.present(viewController, animated: overlay.animated)
    }

    /// The shtorka is asked for but not yet presented from the root. A screen the root shows before it is taken down
    /// when SwiftUI puts the shtorka up, so it waits to go over the shtorka instead.
    func isShtorkaComingUp(over top: UIViewController) -> Bool {
        FeatureProvider.isAvailable(.newShtorkaEnabled)
            && mainBottomSheetUIManager.isShown
            && top === UIApplication.mainWindow?.rootViewController
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard let presented else {
            completion?()
            return
        }

        self.presented = nil

        // Nothing to close while the screen is still waiting for the one on top to finish: dropping it is the
        // whole dismissal, and asking UIKit to dismiss what it never presented would leave the caller waiting
        // for a completion that never comes.
        guard presented.viewController.presentingViewController != nil else {
            completion?()
            return
        }

        presented.viewController.dismiss(animated: presented.overlay.animated, completion: completion)
    }

    static func presentationStyle(for overlay: OverlayView) -> UIModalPresentationStyle {
        switch overlay.style {
        case .sheet:
            return .pageSheet
        case .fullScreenCover:
            // A cover that pops in at once brings its own fade, which it plays over the screen it covers.
            return overlay.animated ? .fullScreen : .overFullScreen
        }
    }
}

// MARK: - Constants

private extension OverlayViewPresentationHost {
    enum Constants {
        static let presentationRetryDelay: TimeInterval = 0.5
    }
}

// MARK: - OverlayHostingController

/// Reports the screen being gone from the display, whoever took it off: the user swiping it away, or the screen
/// it was shown from being closed and taking it along. Being covered by something shown over it doesn't count —
/// the screen is still presented then.
private final class OverlayHostingController<Content: View>: UIHostingController<Content> {
    var didDisappear: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if presentingViewController == nil {
            didDisappear?()
        }
    }
}
