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
    let kingfisherCache: ImageCache = {
        let countLimit = 10
        let tenMinutesInSeconds: TimeInterval = 600

        let cache = ImageCache(name: "com.tangem.stories")
        cache.memoryStorage.config.countLimit = countLimit
        cache.memoryStorage.config.expiration = .seconds(tenMinutesInSeconds)
        cache.memoryStorage.config.keepWhenEnteringBackground = true

        return cache
    }()

    lazy var storyDataCache = InMemoryStoryDataCache(kingfisherCache: kingfisherCache)
    let storyAvailabilityService = AppSettingsStoryAvailabilityService(appSettings: AppSettings.shared)

    lazy var enrichStoryUseCase = EnrichStoryUseCase(storyDataCache: storyDataCache, storyDataService: CommonStoryDataService())
    lazy var tangemStoriesViewModel = TangemStoriesViewModel(
        checkStoryAvailabilityUseCase: CheckStoryAvailabilityUseCase(storyAvailabilityService: storyAvailabilityService),
        enrichStoryUseCase: enrichStoryUseCase,
        finalizeStoryUseCase: FinalizeStoryUseCase(storyAvailabilityService: storyAvailabilityService, storyDataCache: storyDataCache)
    )
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
