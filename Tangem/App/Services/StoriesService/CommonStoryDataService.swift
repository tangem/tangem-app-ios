//
//  StoryApiService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import TangemStories

final class CommonStoryDataService: StoryDataService {
    @Injected(\.tangemApiService) private var tangemApiService: any TangemApiService

    private let storyAvailabilityService: any StoryAvailabilityService
    private let storyAnalyticsService: StoryAnalyticsService

    init(storyAvailabilityService: some StoryAvailabilityService, storyAnalyticsService: StoryAnalyticsService) {
        self.storyAvailabilityService = storyAvailabilityService
        self.storyAnalyticsService = storyAnalyticsService
    }

    func fetchStoryImages(with storyId: TangemStory.ID) async throws -> [TangemStory.Image] {
        let storyDTO: StoryDTO.Response

        do {
            storyDTO = try await fetchStory(storyId: storyId)
        } catch {
            storyAvailabilityService.markStoryAsUnavailableForCurrentSession(storyId)
            storyAnalyticsService.reportLoadingFailed(storyId)
            throw error
        }

        let imageURLs = StoryMapper.mapToImageURLs(storyDTO)
        return try await fetchStoryImages(using: imageURLs)
    }

    // MARK: - Private methods

    private func fetchStory(storyId: TangemStory.ID) async throws -> StoryDTO.Response {
        let requestStoryId = StoryMapper.mapStoryIdToRequestId(storyId)
        return try await tangemApiService.loadStory(storyId: requestStoryId)
    }

    private func fetchStoryImages(using imageURLs: [URL]) async throws -> [TangemStory.Image] {
        try await withThrowingTaskGroup(of: (Int, TangemStory.Image?).self) { [weak self] taskGroup in
            var storyImages = [TangemStory.Image?](repeating: nil, count: imageURLs.count)

            for (index, imageURL) in imageURLs.enumerated() {
                taskGroup.addTask {
                    (index, try await self?.fetchSingleImage(from: imageURL))
                }
            }

            for try await (index, storyImage) in taskGroup {
                storyImages[index] = storyImage
            }

            return storyImages
        }
        .compactMap { $0 }
    }

    private func fetchSingleImage(from imageURL: URL) async throws -> TangemStory.Image {
        let rawData = try await tangemApiService.getRawData(fromURL: imageURL)
        return TangemStory.Image(url: imageURL, rawData: rawData)
    }
}
