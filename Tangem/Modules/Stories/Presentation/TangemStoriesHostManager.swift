//
//  TangemStoriesHostManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import enum TangemStories.TangemStory

final class TangemStoriesHostManager {
    @Injected(\.tangemStoriesViewModel) private var tangemStoriesViewModel: TangemStoriesViewModel
    private var storiesWindow: UIWindow?

    private var storiesViewModelStateCancellable: (any Cancellable)?

    // [REDACTED_TODO_COMMENT]
    func setup(with scene: UIScene, mainWindow: UIWindow?) {
        guard
            let windowScene = scene as? UIWindowScene,
            checkIfThereAreStoriesToShow()
        else {
            return
        }

        storiesWindow = makeWindow(for: windowScene)

        storiesViewModelStateCancellable = tangemStoriesViewModel.$state
            .dropFirst()
            .removeDuplicates()
            .sink { [weak storiesWindow, weak mainWindow] state in
                let isPresentingStories = state != nil
                storiesWindow?.isUserInteractionEnabled = isPresentingStories

                if isPresentingStories {
                    // forces keyboard to hide if showing stories window
                    storiesWindow?.makeKey()
                } else {
                    // restores keyboard for main window if it was previously visible
                    mainWindow?.makeKey()
                }
            }
    }

    private func checkIfThereAreStoriesToShow() -> Bool {
        let allStoryIDs = TangemStory.ID.allCases.map(\.rawValue).toSet()
        let shownStories = AppSettings.shared.shownStoryIds.toSet()
        let remainingStoriesToShow = allStoryIDs.subtracting(shownStories)
        return !remainingStoriesToShow.isEmpty
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
