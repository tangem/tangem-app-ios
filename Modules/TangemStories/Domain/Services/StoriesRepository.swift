//
//  StoriesRepository.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
// schema), placement→id resolution, `.once` visibility, `activeFrom/activeTo` scheduling.
public protocol StoriesRepository {
    func story(id: StoryID) async throws -> StoryV2
    func invalidate(id: StoryID) async
    func invalidateAll() async
}
