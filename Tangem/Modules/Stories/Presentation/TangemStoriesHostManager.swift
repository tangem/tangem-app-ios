//
//  TangemStoriesHostManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemStories

@MainActor
final class TangemStoriesHostManager {
    @Injected(\.tangemStoriesViewModel) private var tangemStoriesViewModel: TangemStoriesViewModel

    private var storiesWindow: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    func setup(with scene: UIScene, mainWindow: UIWindow?) {
        guard let windowScene = scene as? UIWindowScene else { return }

        tangemStoriesViewModel
            .$state
            .sink { [weak self] state in
                if let state {
                    self?.handleNewStoriesState(state, windowScene: windowScene)
                } else {
                    self?.dismissStoriesWindow(
                        completion: {
                            // restores keyboard for main window if it was previously visible
                            mainWindow?.makeKey()
                        }
                    )
                }
            }
            .store(in: &cancellables)
    }

    func forceDismiss() {
        tangemStoriesViewModel.forceDismiss()
    }

    private func handleNewStoriesState(_ state: TangemStoriesViewModel.State, windowScene: UIWindowScene) {
        if storiesWindow == nil {
            makeAndPresentStoriesWindow(for: state, windowScene: windowScene)
        } else {
            updateStoriesWindow(from: state)
        }

        // forces keyboard to hide if showing stories window
        storiesWindow?.makeKey()
    }

    private func dismissStoriesWindow(completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: Self.Animation.disappearingDuration,
            animations: {
                self.storiesWindow?.rootViewController?.view.alpha = 0
            },
            completion: { _ in
                self.storiesWindow = nil
                completion()
            }
        )
    }

    private func makeAndPresentStoriesWindow(for state: TangemStoriesViewModel.State, windowScene: UIWindowScene) {
        storiesWindow = Self.makeStoriesWindow(for: state, windowScene: windowScene)
        UIView.animate(withDuration: Self.Animation.appearingDuration) {
            self.storiesWindow?.rootViewController?.view.alpha = 1
        }
    }

    private func updateStoriesWindow(from state: TangemStoriesViewModel.State?) {
        guard
            let state,
            let storiesWindow,
            let hostingController = storiesWindow.rootViewController?.children.first as? UIHostingController<StoriesHostView>
        else {
            return
        }

        hostingController.rootView = Self.makeRootView(state: state)
    }
}

// MARK: - Nested types

extension TangemStoriesHostManager {
    enum Animation {
        static let appearingDuration: TimeInterval = 0.4
        static let disappearingDuration: TimeInterval = Self.appearingDuration
    }
}

// MARK: - Factory methods

extension TangemStoriesHostManager {
    private static func makeStoriesWindow(for state: TangemStoriesViewModel.State, windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.isHidden = false
        window.isUserInteractionEnabled = true
        window.overrideUserInterfaceStyle = .dark

        window.rootViewController = Self.makeRootViewController(state: state)
        return window
    }

    private static func makeRootViewController(state: TangemStoriesViewModel.State) -> UIViewController {
        let rootViewController = UIViewController()
        rootViewController.view.alpha = 0

        let hostingController = UIHostingController(rootView: Self.makeRootView(state: state))
        hostingController.view.backgroundColor = .black

        // [REDACTED_USERNAME], child view controller in combination with parent opacity tweaking allows to avoid safe area animation bug
        rootViewController.addChild(hostingController)
        rootViewController.view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor),
        ])

        hostingController.didMove(toParent: rootViewController)

        return rootViewController
    }

    private static func makeRootView(state: TangemStoriesViewModel.State) -> StoriesHostView {
        StoriesHostView(
            viewModel: state.storiesHostViewModel,
            storyViews: state.storiesHostViewModel.storyViewModels.map { storyViewModel in
                StoryView(
                    viewModel: storyViewModel,
                    pageViews: Self.makePages(for: state.activeStory, using: state.storiesHostViewModel).map(StoryPageView.init)
                )
            }
        )
    }

    private static func makePages(for story: TangemStory, using viewModel: StoriesHostViewModel) -> [any View] {
        switch story {
        case .swap(let swapStoryData):
            swapStoryData
                .pagesKeyPaths
                .map { pageKeyPath in
                    let page = swapStoryData[keyPath: pageKeyPath]
                    return SwapStoryPageView(page: page)
                }
        }
    }
}
