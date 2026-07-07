//
//  WireMockRedirectPlugin.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Redirects WireMock-bound traffic to the local instance specified via the `WIREMOCK_BASE_URL` env variable.
///
/// Handles two layouts:
/// - the canonical WireMock host (`wiremock.tests-d.com`), whose path already targets the mock — only the host is localized;
/// - real third-party hosts served by WireMock under a host-prefixed path (e.g. `api.etherscan.io/v2/api` ->
///   `<wiremock>/api.etherscan.io/v2/api`) — the host is localized and the original host is prepended to the path.
///
/// This lets providers point at their real production URL while staying hermetic in UI tests, instead of
/// baking the mock decision into the provider itself.
public struct WireMockRedirectPlugin: PluginType {
    private static let wireMockRemoteHost = "wiremock.tests-d.com"

    /// Real third-party hosts whose mocks live under a host-prefixed path on the WireMock server.
    private static let thirdPartyMockedHosts: Set<String> = [
        "api.etherscan.io",
        "deep-index.moralis.io",
        "eth-blockbook.nownodes.io",
    ]

    private let overrideComponents: URLComponents?

    public init() {
        // Maestro passes launch arguments via UserDefaults, not ProcessInfo environment
        let url = ProcessInfo.processInfo.environment["WIREMOCK_BASE_URL"]
            ?? UserDefaults.standard.string(forKey: "WIREMOCK_BASE_URL")
        if let url {
            overrideComponents = URLComponents(string: url)
        } else {
            overrideComponents = nil
        }
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let overrideComponents,
              let originalURL = request.url,
              let host = originalURL.host,
              var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false) else {
            return request
        }

        if host.contains(Self.wireMockRemoteHost) {
            // Already pointing at WireMock; nothing to localize when the override is the remote host too.
            guard overrideComponents.host?.contains(Self.wireMockRemoteHost) != true else {
                return request
            }
        } else if Self.thirdPartyMockedHosts.contains(host) {
            components.path = "/\(host)\(originalURL.path)"
        } else {
            return request
        }

        components.scheme = overrideComponents.scheme
        components.host = overrideComponents.host
        components.port = overrideComponents.port

        guard let newURL = components.url else {
            return request
        }

        var modifiedRequest = request
        modifiedRequest.url = newURL

        #if DEBUG
        print("WireMockRedirect: \(originalURL.absoluteString) -> \(newURL.absoluteString)")
        #endif

        return modifiedRequest
    }
}
