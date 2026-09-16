//
//  FeedNavigation.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedNavigation: AnyObject {
    func push(_ destination: FeedDestination)
    func pop()

    func present(_ destination: FeedDestination)
    func presentFullScreen(_ destination: FeedDestination, zoomingFrom source: FeedZoomSource)
    func dismissPresented()
}
