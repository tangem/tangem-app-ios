//
//  AppSettingsStoryAvailabilityService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Dispatch
import TangemStories

final class AppSettingsStoryAvailabilityService: StoryAvailabilityService {
    private let appSettings: AppSettings
    private let unavailableForCurrentSessionStoryIdsSubject: CurrentValueSubject<Set<TangemStory.ID>, Never>
    private let queue: DispatchQueue

    let availableStoriesPublisher: AnyPublisher<Set<TangemStory.ID>, Never>

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        unavailableForCurrentSessionStoryIdsSubject = CurrentValueSubject([])
        queue = DispatchQueue(label: "com.tangem.AppSettingsStoryAvailabilityService", attributes: .concurrent)

        availableStoriesPublisher = appSettings.$shownStoryIds
            .combineLatest(unavailableForCurrentSessionStoryIdsSubject)
            .map { shownStoryRawIdentifiers, unavailableForCurrentSessionStoryIdentifiers in
                let shownStoryIdentifiers = shownStoryRawIdentifiers.compactMap(TangemStory.ID.init)
                let allStoryIdentifiers = Set(TangemStory.ID.allCases)

                let remainingStoryIdentifiers = allStoryIdentifiers
                    .subtracting(shownStoryIdentifiers)
                    .subtracting(unavailableForCurrentSessionStoryIdentifiers)

                return remainingStoryIdentifiers
            }
            .eraseToAnyPublisher()
    }

    func checkStoryAvailability(storyId: TangemStory.ID) -> Bool {
        let storyWasShown = appSettings.shownStoryIds.contains(storyId.rawValue)
        let storyIsUnavailableForCurrentSession = queue.sync { [unavailableForCurrentSessionStoryIdsSubject] in
            unavailableForCurrentSessionStoryIdsSubject.value.contains(storyId)
        }
        return !storyWasShown && !storyIsUnavailableForCurrentSession
    }

    func markStoryAsShown(storyId: TangemStory.ID) {
        appSettings.shownStoryIds.insert(storyId.rawValue)
    }

    func markStoryAsUnavailableForCurrentSession(_ storyId: TangemStory.ID) {
        queue.async(flags: .barrier) { [unavailableForCurrentSessionStoryIdsSubject] in
            var unavailableStoryIds = unavailableForCurrentSessionStoryIdsSubject.value
            unavailableStoryIds.insert(storyId)
            unavailableForCurrentSessionStoryIdsSubject.send(unavailableStoryIds)
        }
    }
}
