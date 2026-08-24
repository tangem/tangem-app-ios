//
//  InMemoryStoriesDataSource.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public actor InMemoryStoriesDataSource: StoriesDataSource {
    private var stored: [StoryID: StoryV2] = [:]

    public init() {}

    public func read(id: StoryID) -> StoryV2? { stored[id] }

    public func write(_ story: StoryV2, id: StoryID) { stored[id] = story }

    public func remove(id: StoryID) { stored[id] = nil }

    public func removeAll() { stored.removeAll() }
}
