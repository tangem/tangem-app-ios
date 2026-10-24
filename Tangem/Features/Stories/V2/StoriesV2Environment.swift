//
//  StoriesV2Environment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

private final class StoriesV2Environment {
    let assetPrefetchService: StoryAssetPrefetchService
    let remoteStore: StoriesV2RemoteStore
    let prefetchService: StoriesV2PrefetchService
    let presenter: CommonStoriesV2Presenter

    init() {
        assetPrefetchService = StoryAssetPrefetchService(cache: CommonStoryAssetCache())
        remoteStore = StoriesV2RemoteStore(
            mapper: StoriesDTOMapper(allowedWebHosts: Constants.allowedWebHosts, origin: .remote)
        )
        prefetchService = StoriesV2PrefetchService()
        presenter = CommonStoriesV2Presenter()
    }
}

// MARK: - Constants

private extension StoriesV2Environment {
    enum Constants {
        /// Web-action allowlist from the /v2/stories contract.
        static let allowedWebHosts: Set<String> = [
            "tangem.com", "www.tangem.com", "buy.tangem.com", "app.tangem.com",
            "promo.tangem.com", "feedback.tangem.com", "tangem.surveysparrow.com",
        ]
    }
}

private struct StoriesV2EnvironmentKey: InjectionKey {
    static var currentValue = StoriesV2Environment()
}

// MARK: - InjectedValues access properties

extension InjectedValues {
    private var storiesV2Environment: StoriesV2Environment {
        get { Self[StoriesV2EnvironmentKey.self] }
        set { Self[StoriesV2EnvironmentKey.self] = newValue }
    }

    var storiesV2AssetPrefetchService: StoryAssetPrefetchService {
        storiesV2Environment.assetPrefetchService
    }

    var storiesV2RemoteStore: StoriesV2RemoteStore {
        storiesV2Environment.remoteStore
    }

    var storiesV2PrefetchService: StoriesV2PrefetchService {
        storiesV2Environment.prefetchService
    }

    var storiesV2Presenter: any StoriesV2Presenter {
        storiesV2Environment.presenter
    }
}
