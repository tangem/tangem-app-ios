//
//  StoryApiService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import protocol TangemStories.StoryDataService
import enum TangemStories.TangemStory

final class CommonStoryDataService: StoryDataService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    func fetchStoryImages(with storyId: TangemStory.ID) async throws -> [TangemStory.Image] {
        let storyDTO = try await fetchStory(storyId: storyId)
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
