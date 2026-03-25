//
//  WireMockRedirectPlugin.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Redirects requests to the remote WireMock host (`wiremock.tests-d.com`)
/// to a local WireMock instance specified via `WIREMOCK_BASE_URL` env variable.
public struct WireMockRedirectPlugin: PluginType {
    private static let wireMockRemoteHost = "wiremock.tests-d.com"

    private let overrideComponents: URLComponents?

    public init() {
        if let url = ProcessInfo.processInfo.environment["WIREMOCK_BASE_URL"] {
            overrideComponents = URLComponents(string: url)
        } else {
            overrideComponents = nil
        }
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let overrideComponents,
              let originalURL = request.url,
              let host = originalURL.host,
              host.contains(Self.wireMockRemoteHost) else {
            return request
        }

        if overrideComponents.host?.contains(Self.wireMockRemoteHost) == true {
            return request
        }

        guard var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false) else {
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
