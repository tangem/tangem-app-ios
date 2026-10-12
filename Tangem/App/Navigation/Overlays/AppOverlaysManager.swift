//
//  AppOverlaysManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import class Kingfisher.ImageCache
import TangemStories
import TangemUIUtils
import TangemUI

@MainActor
final class AppOverlaysManager {
    private let sheetRegistry: FloatingSheetRegistry

    @Injected(\.tangemStoriesViewModel) private var tangemStoriesViewModel: TangemStoriesViewModel
    @Injected(\.storyKingfisherImageCache) private var storyKingfisherImageCache: ImageCache
    @Injected(\.storiesV2Presenter) private var storiesV2Presenter: any StoriesV2Presenter

    @Injected(\.appOverlaysDependencies.alertPresenterViewModel) private var alertPresenterViewModel: AlertPresenterViewModel
    @Injected(\.appOverlaysDependencies.floatingSheetViewModel) private var floatingSheetViewModel: FloatingSheetViewModel
    @Injected(\.appOverlaysDependencies.overlayShareActivitiesViewModel) private var shareActivitiesViewModel: ShareActivitiesViewModel
    @Injected(\.appOverlaysDependencies.overlayViewPresenterViewModel) private var overlayViewPresenterViewModel: OverlayViewPresenterViewModel

    private var overlayWindow: UIWindow?
    private var storiesViewController: UIViewController?
    private var storiesV2ViewController: UIViewController?
    private var overlayPresentationHost: OverlayViewPresentationHost?

    private var cancellables: Set<AnyCancellable>
    private weak var mainWindow: MainWindow?

    init(sheetRegistry: FloatingSheetRegistry) {
        self.sheetRegistry = sheetRegistry
        cancellables = []
    }

    func setup(with scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // [REDACTED_USERNAME], initial pause in case there will be some sheets to display before app is in a proper state
        floatingSheetViewModel.pauseSheetsDisplaying()

        overlayWindow = Self.makeOverlayWindow(
            from: windowScene,
            sheetViewModel: floatingSheetViewModel,
            sheetRegistry: sheetRegistry,
            alertPresenterViewModel: alertPresenterViewModel
        )

        overlayPresentationHost = OverlayViewPresentationHost(
            viewModel: overlayViewPresenterViewModel,
            sheetRegistry: sheetRegistry
        )

        bindStories()
        bindActiveSheet()
        bindAppTheme()
    }

    func setMainWindow(_ mainWindow: MainWindow) {
        self.mainWindow = mainWindow
    }

    func forceDismiss() {
        floatingSheetViewModel.removeAllSheets()
        floatingSheetViewModel.pauseSheetsDisplaying()
        overlayViewPresenterViewModel.dismissAll()

        tangemStoriesViewModel.forceDismiss()
        storiesV2Presenter.forceDismiss()
    }

    // MARK: - Private methods

    private func bindStories() {
        tangemStoriesViewModel
            .$state
            .sink { [weak self] state in
                self?.handleNewStoriesState(state)
            }
            .store(in: &cancellables)

        storiesV2Presenter
            .playerPublisher
            .sink { [weak self] player in
                self?.handleNewStoriesV2Player(player)
            }
            .store(in: &cancellables)

        shareActivitiesViewModel
            .$activityItems
            .dropFirst()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { manager, activityItems in
                guard let activityItems, !activityItems.isEmpty else { return }

                let av = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                manager.present(viewController: av)
            }
            .store(in: &cancellables)
    }

    private func bindActiveSheet() {
        floatingSheetViewModel
            .$activeSheet
            .dropFirst()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { manager, activeSheet in
                manager.updateOverlayAccessibility(hasActiveSheet: activeSheet != nil)
                if activeSheet == nil {
                    manager.restoreMainWindowKeyboardIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    /// Bridges the overlay window into Maestro's accessibility snapshot.
    private func updateOverlayAccessibility(hasActiveSheet: Bool) {
        overlayWindow?.rootViewController?.view.accessibilityViewIsModal = hasActiveSheet
    }

    private func bindAppTheme() {
        AppSettings.shared
            .$appTheme
            .dropFirst()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { manager, newAppTheme in
                manager.overlayWindow?.overrideUserInterfaceStyle = newAppTheme.interfaceStyle
            }
            .store(in: &cancellables)
    }

    private func present(viewController: UIViewController) {
        overlayWindow?.rootViewController?.present(viewController, animated: true)
    }

    private func handleNewStoriesState(_ state: TangemStoriesViewModel.State?) {
        guard let state else {
            dismissStoriesViewController()
            return
        }

        if let storiesViewController {
            Self.updateStoriesViewController(storiesViewController, with: state, imageCache: storyKingfisherImageCache)
        } else {
            let storiesViewController = Self.makeStoriesViewController(for: state, imageCache: storyKingfisherImageCache)
            self.storiesViewController = storiesViewController

            overlayWindow?.rootViewController?.present(storiesViewController, animated: true)
            // forces keyboard to hide if showing stories window
            overlayWindow?.makeKey()
        }
    }

    private static func updateStoriesViewController(
        _ viewController: UIViewController,
        with state: TangemStoriesViewModel.State,
        imageCache: ImageCache
    ) {
        guard let hostingController = viewController.children.first as? UIHostingController<StoriesHostView> else { return }
        hostingController.rootView = Self.makeStoriesHostView(for: state, imageCache: imageCache)
    }

    private func handleNewStoriesV2Player(_ player: StoryPlayerViewModel?) {
        guard let player else {
            dismissStoriesV2ViewController()
            return
        }

        // A story arriving while the root is busy — the previous one still dismissing, a V1 story or
        // a share sheet up — is dropped, and handed back so the presenter does not keep reporting a
        // player that nothing shows. Its caller still gets the destination. The slot is claimed only
        // once the presentation actually starts, otherwise a refused story would hold it for the
        // rest of the session.
        guard
            storiesV2ViewController == nil,
            let rootViewController = overlayWindow?.rootViewController,
            rootViewController.presentedViewController == nil
        else {
            storiesV2Presenter.releaseUnpresented(player)
            return
        }

        let viewController = Self.makeStoriesV2ViewController(for: player)
        storiesV2ViewController = viewController

        rootViewController.present(viewController, animated: true)
        // forces keyboard to hide if showing stories window
        overlayWindow?.makeKey()
    }

    private func dismissStoriesV2ViewController() {
        storiesV2ViewController?.dismiss(
            animated: true,
            completion: { [weak self] in
                self?.storiesV2ViewController = nil
                self?.restoreMainWindowKeyboardIfNeeded()
            }
        )
    }

    private func dismissStoriesViewController() {
        storiesViewController?.dismiss(
            animated: true,
            completion: { [weak self] in
                self?.storiesViewController = nil
                self?.restoreMainWindowKeyboardIfNeeded()
            }
        )
    }

    /// Restores keyboard for main window if it was previously visible.
    private func restoreMainWindowKeyboardIfNeeded() {
        mainWindow?.makeKey()
    }
}

// MARK: - Factory methods

extension AppOverlaysManager {
    private static func makeOverlayWindow(
        from windowScene: UIWindowScene,
        sheetViewModel: FloatingSheetViewModel,
        sheetRegistry: FloatingSheetRegistry,
        alertPresenterViewModel: AlertPresenterViewModel
    ) -> UIWindow {
        let rootView = OverlayRootView(
            floatingSheetViewModel: sheetViewModel,
            alertPresenterViewModel: alertPresenterViewModel
        )
        .environment(\.floatingSheetRegistry, sheetRegistry)

        let rootViewController = UIHostingController(rootView: rootView)
        rootViewController.view.backgroundColor = .clear

        let window = PassThroughWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
        window.isHidden = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.rootViewController = rootViewController

        return window
    }

    private static func makeStoriesViewController(for state: TangemStoriesViewModel.State, imageCache: ImageCache) -> UIViewController {
        let containerViewController = UIViewController()
        containerViewController.view.backgroundColor = .black
        containerViewController.overrideUserInterfaceStyle = .dark
        containerViewController.modalPresentationStyle = .fullScreen
        containerViewController.modalTransitionStyle = .crossDissolve

        let storiesViewController = UIHostingController(rootView: Self.makeStoriesHostView(for: state, imageCache: imageCache))

        // [REDACTED_USERNAME], child view controller in combination with parent opacity tweaking allows to avoid safe area animation bug
        containerViewController.addChild(storiesViewController)
        containerViewController.view.addSubview(storiesViewController.view)

        storiesViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            storiesViewController.view.leadingAnchor.constraint(equalTo: containerViewController.view.leadingAnchor),
            storiesViewController.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor),
            storiesViewController.view.trailingAnchor.constraint(equalTo: containerViewController.view.trailingAnchor),
            storiesViewController.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor),
        ])

        containerViewController.didMove(toParent: containerViewController)

        return containerViewController
    }

    /// Nested in a plain container rather than presented directly, which keeps the safe area from
    /// animating on presentation — same reason as the V1 stories controller above.
    private static func makeStoriesV2ViewController(for player: StoryPlayerViewModel) -> UIViewController {
        let containerViewController = UIViewController()
        containerViewController.view.backgroundColor = .black
        containerViewController.overrideUserInterfaceStyle = .dark
        containerViewController.modalPresentationStyle = .fullScreen
        containerViewController.modalTransitionStyle = .crossDissolve

        let playerViewController = UIHostingController(rootView: StoryPlayerView(vm: player))

        containerViewController.addChild(playerViewController)
        containerViewController.view.addSubview(playerViewController.view)

        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerViewController.view.leadingAnchor.constraint(equalTo: containerViewController.view.leadingAnchor),
            playerViewController.view.topAnchor.constraint(equalTo: containerViewController.view.topAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: containerViewController.view.trailingAnchor),
            playerViewController.view.bottomAnchor.constraint(equalTo: containerViewController.view.bottomAnchor),
        ])

        playerViewController.didMove(toParent: containerViewController)

        return containerViewController
    }

    private static func makeStoriesHostView(for state: TangemStoriesViewModel.State, imageCache: ImageCache) -> StoriesHostView {
        StoriesHostView(
            viewModel: state.storiesHostViewModel,
            storyViews: state.storiesHostViewModel.storyViewModels.map { storyViewModel in
                let pageViews = Self.makeStoryPages(for: state.activeStory, using: state.storiesHostViewModel, imageCache: imageCache)
                    .map { StoryPageContainerView(content: $0, ignoresBottomSafeArea: state.activeStory.runsArtToTheBottomEdge) }

                return StoryView(viewModel: storyViewModel, pageViews: pageViews)
            }
        )
    }

    private static func makeStoryPages(for story: TangemStory, using viewModel: StoriesHostViewModel, imageCache: ImageCache) -> [any View] {
        story.pages.map { page in
            StoryPageView(page: page, kingfisherImageCache: imageCache)
        }
    }
}
