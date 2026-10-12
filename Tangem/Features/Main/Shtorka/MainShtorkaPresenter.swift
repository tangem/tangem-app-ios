//
//  MainShtorkaPresenter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The markets sheet of the main screen: its state, the feed inside it and the way to raise it, kept together.
/// The screen asks for the feed it wants and takes no part in how the sheet gets there.
final class MainShtorkaPresenter {
    @Injected(\.mainBottomSheetUIManager) private var bottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.overlayContentStateController) private var overlayContentStateController: OverlayContentStateController

    /// The native sheet, when it is the one in use. With it off the legacy shtorka takes the screen's place in
    /// the bottom sheet, and there is nothing here to build it from.
    private(set) var content: Content?

    init(host: FeedHostRoutable, popToRootAction: @escaping Action<PopToRootOptions>) {
        guard FeatureProvider.isAvailable(.newShtorkaEnabled) else {
            return
        }

        let state = MainShtorkaStateObject()
        let feed = FeedCoordinator(popToRootAction: popToRootAction)
        feed.start(with: .init(container: state, host: host))

        content = Content(state: state, feed: feed)
    }

    deinit {
        content?.state.stopFollowingBottomSheet()
    }

    /// Brings the sheet up on the feed the link asks for. The legacy shtorka has no sections to be pointed at,
    /// so it is raised as it is.
    func open(selection: FeedSelection) {
        bottomSheetUIManager.show()

        guard let content else {
            overlayContentStateController.expand()
            return
        }

        content.feed.apply(selection: selection)
        content.state.expand()
    }
}

// MARK: - Content

extension MainShtorkaPresenter {
    struct Content {
        let state: MainShtorkaStateObject
        let feed: FeedCoordinator
    }
}
