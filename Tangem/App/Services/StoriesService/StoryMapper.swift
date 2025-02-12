//
//  StoryMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import enum TangemStories.TangemStory

enum StoryMapper {
    static func mapStoryIdToRequestId(_ storyId: TangemStory.ID) -> String {
        switch storyId {
        case .swap: "first-time-swap"
        }
    }

    static func mapToImageURLs(_ storyDTO: StoryDTO.Response) -> [URL] {
        storyDTO.story.slides.compactMap {
            storyDTO.imageHost
                .appendingPathComponent($0.id)
                .appendingPathExtension(for: .webP)
        }
    }
}
