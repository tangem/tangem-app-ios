//
//  AppSettingsStoryAvailabilityService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol TangemStories.StoryAvailabilityService
import enum TangemStories.TangemStory

final class AppSettingsStoryAvailabilityService: StoryAvailabilityService {
    private let appSettings: AppSettings

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }

    func checkStoryAvailability(storyId: TangemStory.ID) -> Bool {
        let storyWasShown = appSettings.shownStoryIds.contains(storyId.rawValue)
        return !storyWasShown
    }

    func markStoryAsShown(storyId: TangemStory.ID) {
        appSettings.shownStoryIds.insert(storyId.rawValue)
    }
}
