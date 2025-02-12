//
//  StoryAvailabilityService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol StoryAvailabilityService {
    func checkStoryAvailability(storyId: TangemStory.ID) -> Bool
    func markStoryAsShown(storyId: TangemStory.ID)
}
