//
//  InMemoryStoriesSeenStatusProvider.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public actor InMemoryStoriesSeenStatusProvider: StoriesSeenStatusProvider {
    private var seen: Set<StoryID> = []

    public init() {}

    public func isSeen(for storyId: StoryID) -> Bool { seen.contains(storyId) }

    public func markAsSeen(storyId: StoryID) { seen.insert(storyId) }
}
