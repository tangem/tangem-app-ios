//
//  QAToolsClient.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

enum WCNetwork: String {
    case ethereum
    case solana
}

enum WCURIScheme: String {
    case tangem = "tangem://wc"
    case appTangem = "https://app.tangem.com/wc"
}

final class QAToolsClient {
    private let baseURL: String

    init(baseURL: String = "https://qa-tools.tests-d.com") {
        self.baseURL = baseURL
    }

    func getWCURI(
        network: WCNetwork = .ethereum,
        uriScheme: WCURIScheme = .tangem
    ) async throws -> String {
        var urlComponents = URLComponents(string: "\(baseURL)/wc_uri")!
        urlComponents.queryItems = [
            URLQueryItem(name: "network", value: network.rawValue),
        ]

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

            guard let baseURL = URL(string: uriScheme.rawValue),
                  let baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL)
            }

            var urlComponents = URLComponents()
            urlComponents.scheme = baseComponents.scheme
            urlComponents.host = baseComponents.host
            urlComponents.path = baseComponents.path
            urlComponents.queryItems = [
                URLQueryItem(name: "uri", value: wcResponse.wcUri),
            ]

            guard let finalURL = urlComponents.url else {
                throw URLError(.badURL)
            }

            return finalURL.absoluteString
        } catch {
            throw error
        }
    }

    func getAddresses(id: String) async throws -> [WalletInfoJSON] {
        var urlComponents = URLComponents(string: "\(baseURL)/addresses")!
        urlComponents.queryItems = [
            URLQueryItem(name: "id", value: id),
        ]

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
            let addressesResponse = try JSONDecoder().decode(AddressesResponse.self, from: data)
            return addressesResponse.data
        } catch {
            throw error
        }
    }

    // MARK: - Sync Wrappers for XCTest

    func getWCURISync(
        network: WCNetwork = .ethereum,
        uriScheme: WCURIScheme,
        timeout: TimeInterval = .networkRequest
    ) -> String {
        let expectation = XCTestExpectation(description: "Get WC URI")
        var result = ""

        Task {
            do {
                result = try await getWCURI(network: network, uriScheme: uriScheme)
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

    func getAddressesSync(id: String, timeout: TimeInterval = .networkRequest) -> [WalletInfoJSON] {
        let expectation = XCTestExpectation(description: "Get addresses")
        var result: [WalletInfoJSON] = []

        Task {
            do {
                result = try await getAddresses(id: id)
                expectation.fulfill()
            } catch {
                XCTFail("Failed to get addresses: \(error)")
                expectation.fulfill()
            }
        }

        XCTestCase().wait(for: [expectation], timeout: timeout)
        return result
    }
}
