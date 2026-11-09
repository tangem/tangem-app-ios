//
//  CommonFileAssetDownloader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct CommonFileAssetDownloader: FileAssetDownloader {
    private let session: URLSession

    init(session: URLSession = TangemTrustEvaluatorUtil.makeSession(configuration: .fileAssets)) {
        self.session = session
    }

    func downloadFile(from url: URL) async throws -> URL {
        let (tempURL, response) = try await session.download(from: url)

        if let httpResponse = response as? HTTPURLResponse, !(200 ..< 300).contains(httpResponse.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw FileAssetDownloaderError.unacceptableStatusCode(httpResponse.statusCode)
        }

        return tempURL
    }
}

enum FileAssetDownloaderError: Error {
    case unacceptableStatusCode(Int)
}

private extension URLSessionConfiguration {
    /// Cached videos reach several megabytes, so the resource timeout allows a slow-network download.
    static let fileAssets: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        return configuration
    }()
}
