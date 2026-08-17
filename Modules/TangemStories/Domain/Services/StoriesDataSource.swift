//
//  StoriesDataSource.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
public protocol StoriesDataSource: Actor {
    func read(id: StoryID) -> StoryV2?
    func write(_ story: StoryV2, id: StoryID)
    func remove(id: StoryID)
    func removeAll()
}
