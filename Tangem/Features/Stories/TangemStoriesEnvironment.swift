//
//  TangemStoriesEnvironment.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import typealias Foundation.TimeInterval
import TangemStories
import Kingfisher

private final class TangemStoriesEnvironment {
    let kingfisherCache: ImageCache
    let storyAvailabilityService: AppSettingsStoryAvailabilityService
    let enrichStoryUseCase: EnrichStoryUseCase
    let tangemStoriesViewModel: TangemStoriesViewModel

    init() {
        let countLimit = 10
        let tenMinutesInSeconds: TimeInterval = 600

        let kingfisherCache = ImageCache(name: "com.tangem.stories")
        kingfisherCache.memoryStorage.config.countLimit = countLimit
        kingfisherCache.memoryStorage.config.expiration = .seconds(tenMinutesInSeconds)
        kingfisherCache.memoryStorage.config.keepWhenEnteringBackground = true

        let storyDataCache = InMemoryStoryDataCache(kingfisherCache: kingfisherCache)
        let storyAvailabilityService = AppSettingsStoryAvailabilityService(appSettings: AppSettings.shared)
        let storyAnalyticsService = StoryAnalyticsService()

        let enrichStoryUseCase = EnrichStoryUseCase(
            storyDataCache: storyDataCache,
            storyDataService: CommonStoryDataService(
                storyAvailabilityService: storyAvailabilityService,
                storyAnalyticsService: storyAnalyticsService
            )
        )

        self.kingfisherCache = kingfisherCache
        self.storyAvailabilityService = storyAvailabilityService
        self.enrichStoryUseCase = enrichStoryUseCase

        tangemStoriesViewModel = TangemStoriesViewModel(
            checkStoryAvailabilityUseCase: CheckStoryAvailabilityUseCase(storyAvailabilityService: storyAvailabilityService),
            enrichStoryUseCase: enrichStoryUseCase,
            finalizeStoryUseCase: FinalizeStoryUseCase(storyAvailabilityService: storyAvailabilityService, storyDataCache: storyDataCache),
            analyticsService: storyAnalyticsService
        )
    }
}

private struct TangemStoriesEnvironmentKey: InjectionKey {
    static var currentValue = TangemStoriesEnvironment()
}

// MARK: - InjectedValues access properties

extension InjectedValues {
    private var tangemStoriesEnvironment: TangemStoriesEnvironment {
        get { Self[TangemStoriesEnvironmentKey.self] }
        set { Self[TangemStoriesEnvironmentKey.self] = newValue }
    }

    var storyKingfisherImageCache: ImageCache {
        tangemStoriesEnvironment.kingfisherCache
    }

    var storyAvailabilityService: any StoryAvailabilityService {
        tangemStoriesEnvironment.storyAvailabilityService
    }

    var enrichStoryUseCase: EnrichStoryUseCase {
        tangemStoriesEnvironment.enrichStoryUseCase
    }

    var tangemStoriesViewModel: TangemStoriesViewModel {
        tangemStoriesEnvironment.tangemStoriesViewModel
    }

    var tangemStoriesPresenter: any TangemStoriesPresenter {
        tangemStoriesEnvironment.tangemStoriesViewModel
    }
}

// MARK: - Story factory

extension TangemStory {
    static var yieldFirstActivationAPYBoostStory: TangemStory {
        .yieldFirstActivationAPYBoost(.initialWithoutImages)
    }
}
