//
//  StoryDataService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol StoryDataService {
    func fetchStoryImages(with storyId: TangemStory.ID) async throws -> [TangemStory.Image]
}
