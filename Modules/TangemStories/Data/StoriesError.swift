//
//  StoriesError.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum StoriesError: Error {
    case storyNotFound(id: StoryID)
    case loadFailed(underlying: Error)
    case decodingFailed(underlying: Error)
}
