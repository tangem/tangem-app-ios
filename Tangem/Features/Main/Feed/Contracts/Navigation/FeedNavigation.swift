//
//  FeedNavigation.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedNavigation: AnyObject {
    var isAtRoot: Bool { get }
    var isFeedPresented: Bool { get }
    var presented: FeedDestination? { get }

    func push(_ destination: FeedDestination)
    func pushAfterSheetExpansion(_ destination: FeedDestination)
    func pop()
    func selectTab(_ kind: FeedTabKind)

    func present(_ destination: FeedDestination, onDismiss: (() -> Void)?)
    func presentFullScreen(_ destination: FeedDestination, zoomingFrom source: FeedZoomSource)
    func dismissPresented()

    func presentModal(_ modal: FeedModal)
    func dismissModal()
}

extension FeedNavigation {
    func present(_ destination: FeedDestination) {
        present(destination, onDismiss: nil)
    }
}
