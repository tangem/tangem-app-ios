//
//  TangemStoriesEnvironment.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStories
import class Kingfisher.KingfisherManager

private final class TangemStoriesEnvironment {
    let storyDataCache = InMemoryStoryDataCache(kingfisherCache: KingfisherManager.shared.cache)
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
