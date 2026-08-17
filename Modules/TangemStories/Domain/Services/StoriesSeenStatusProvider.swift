//
//  StoriesSeenStatusProvider.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol StoriesSeenStatusProvider: Actor {
    func isSeen(for storyId: StoryID) -> Bool
    func markAsSeen(storyId: StoryID)
}
