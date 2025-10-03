//
//  QAToolsClient.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class QAToolsClient {
    private let baseURL: String

    init(baseURL: String = "https://qa-tools.tests-d.com") {
        self.baseURL = baseURL
    }

    func getWCURI() async throws -> String {
        var urlComponents = URLComponents(string: "\(baseURL)/wc_uri")!

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        do {
            let wcResponse = try JSONDecoder().decode(WCURIResponse.self, from: data)

            guard wcResponse.success else {
                throw URLError(.badServerResponse)
            }

            return "tangem://wc?uri=\(wcResponse.wcUri)"
        } catch {
            throw error
        }
    }

    // MARK: - Sync Wrappers for XCTest

    func getWCURISync(timeout: TimeInterval = .networkRequest) -> String {
        let expectation = XCTestExpectation(description: "Get WC URI")
        var result = ""

        Task {
            do {
                result = try await getWCURI()
                print("Received deeplink: \(result)")
                expectation.fulfill()
            } catch {
                XCTFail("Failed to get WC URI: \(error)")
                expectation.fulfill()
            }
        }

        XCTestCase().wait(for: [expectation], timeout: timeout)
        return result
    }
}
