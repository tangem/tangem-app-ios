//
//  FeedCover.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeedCover: Identifiable {
    let destination: FeedDestination
    let zoomSource: FeedZoomSource

    var id: FeedDestination.ID { destination.id }
}
