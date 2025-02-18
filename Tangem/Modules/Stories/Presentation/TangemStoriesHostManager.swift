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
    @Injected(\.storyAvailabilityService) private var storyAvailableService: any StoryAvailabilityService
    @Injected(\.tangemStoriesViewModel) private var tangemStoriesViewModel: TangemStoriesViewModel

    private var storiesWindow: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    // [REDACTED_TODO_COMMENT]
    func setup(with scene: UIScene, mainWindow: UIWindow?) {
        guard let windowScene = scene as? UIWindowScene else { return }

        storyAvailableService
            .availableStoriesPublisher
            .removeDuplicates()
            .combineLatest(
                tangemStoriesViewModel
                    .$state
                    .removeDuplicates()
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] availableStoryIdentifiers, state in
                guard let self else { return }

                let hasAnyStoryToShow = !availableStoryIdentifiers.isEmpty
                let isPresentingStories = state != nil

                setupStoriesWindowIfNeeded(hasAnyStoryToShow: hasAnyStoryToShow, windowScene: windowScene)
                updateWindowsState(isPresentingStories: isPresentingStories, mainWindow: mainWindow)
            }
            .store(in: &cancellables)
    }

    func forceDismiss() {
        tangemStoriesViewModel.forceDismiss()
    }

    private func setupStoriesWindowIfNeeded(hasAnyStoryToShow: Bool, windowScene: UIWindowScene) {
        guard storiesWindow == nil, hasAnyStoryToShow else { return }
        storiesWindow = makeWindow(for: windowScene)
    }

    private func updateWindowsState(isPresentingStories: Bool, mainWindow: UIWindow?) {
        storiesWindow?.isUserInteractionEnabled = isPresentingStories

        if isPresentingStories {
            // forces keyboard to hide if showing stories window
            storiesWindow?.makeKey()
        } else {
            // restores keyboard for main window if it was previously visible
            mainWindow?.makeKey()
        }
    }

    private func makeWindow(for windowScene: UIWindowScene) -> UIWindow {
        let rootView = TangemStoriesHostView(viewModel: tangemStoriesViewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear

        let storiesWindow = UIWindow(windowScene: windowScene)
        storiesWindow.windowLevel = .alert + 1
        storiesWindow.rootViewController = hostingController
        storiesWindow.isHidden = false
        storiesWindow.isUserInteractionEnabled = false

        return storiesWindow
    }
}
