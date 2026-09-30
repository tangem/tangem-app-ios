//
//  StoriesV2RemoteStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStories

/// A reference type so every caller shares `requests`; a second instance would coalesce nothing.
final class StoriesV2RemoteStore {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let mapper: StoriesDTOMapper

    private let requests = KeyedTaskProcessor<[String], [StoryV2]>()

    init(mapper: StoriesDTOMapper) {
        self.mapper = mapper
    }

    /// The language goes as a query item, not a header: `Accept-Language` carries the device
    /// language, while stories follow the app's. It is passed whole — the content codes include
    /// `pt-BR`, `zh-Hans` and `zh-Hant`, which two-letter codes cannot express.
    func stories(slugs: [String]) async throws -> [StoryV2] {
        try await requests.execute(forKey: slugs) { [tangemApiService, mapper] in
            let response = try await tangemApiService.loadStories(slugs: slugs, language: Locale.appLanguageCode)

            return mapper.map(response)
        }
    }
}
