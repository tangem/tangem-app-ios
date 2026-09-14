//
//  CommonStoriesDataLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct CommonStoriesDataLoader: StoriesDataLoader {
    private let session: URLSession

    init(session: URLSession = TangemTrustEvaluatorUtil.makeSession(configuration: .storyAssets)) {
        self.session = session
    }

    func downloadFile(from url: URL) async throws -> URL {
        let (tempURL, response) = try await session.download(from: url)

        if let httpResponse = response as? HTTPURLResponse, !(200 ..< 300).contains(httpResponse.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw StoriesDataLoaderError.unacceptableStatusCode(httpResponse.statusCode)
        }

        return tempURL
    }
}

enum StoriesDataLoaderError: Error {
    case unacceptableStatusCode(Int)
}

private extension URLSessionConfiguration {
    /// Story videos reach several megabytes, so the resource timeout allows a slow-network download.
    static let storyAssets: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        return configuration
    }()
}
