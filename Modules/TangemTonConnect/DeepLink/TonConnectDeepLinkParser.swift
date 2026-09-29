//
//  TonConnectDeepLinkParser.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Parses `tc://…`, universal-link and custom-scheme TON Connect URLs into `TonConnectDeepLink`.
///
/// The parser only looks at the query string, so the caller decides which URLs are routed here
/// (the `tc` scheme, the wallet's own scheme, the `/ton-connect` universal-link path). Embedded
/// requests (`e`) are ignored: this wallet does not advertise the `EmbeddedRequest` feature.
public struct TonConnectDeepLinkParser: Sendable {
    public static let unifiedScheme = "tc"
    public static let supportedProtocolVersion = TonConnectDeviceInfo.supportedProtocolVersion

    private enum Parameter {
        static let version = "v"
        static let clientID = "id"
        static let request = "r"
        static let returnStrategy = "ret"
        static let traceID = "trace_id"
    }

    public init() {}

    /// `true` when `url` is a unified `tc://` link. Universal/custom-scheme links are recognised by the app.
    public func isUnifiedLink(_ url: URL) -> Bool {
        url.scheme?.lowercased() == Self.unifiedScheme
    }

    public func parse(_ url: URL) throws -> TonConnectDeepLink {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TonConnectError.malformedConnectRequest("URL cannot be parsed")
        }

        let query = Dictionary(
            (components.queryItems ?? []).compactMap { item -> (String, String)? in
                guard let value = item.value else { return nil }
                return (item.name, value)
            },
            uniquingKeysWith: { first, _ in first }
        )

        guard let clientIDHex = query[Parameter.clientID] else {
            throw TonConnectError.malformedConnectRequest("missing id")
        }
        let dAppClientID = try TonConnectClientID(hexString: clientIDHex)

        let connectRequest = try query[Parameter.request].map(decodeConnectRequest)

        let protocolVersion: Int
        if connectRequest != nil {
            // `v` is mandatory on a connect link; the "empty" return-only link may omit it.
            let rawVersion = query[Parameter.version]
            guard let version = rawVersion.flatMap(Int.init), version == Self.supportedProtocolVersion else {
                throw TonConnectError.unsupportedProtocolVersion(rawVersion)
            }
            protocolVersion = version
        } else {
            protocolVersion = query[Parameter.version].flatMap(Int.init) ?? Self.supportedProtocolVersion
        }

        return TonConnectDeepLink(
            protocolVersion: protocolVersion,
            dAppClientID: dAppClientID,
            connectRequest: connectRequest,
            returnStrategy: parseReturnStrategy(query[Parameter.returnStrategy]),
            traceID: query[Parameter.traceID]
        )
    }

    private func decodeConnectRequest(_ json: String) throws -> TonConnectConnectRequest {
        let request: TonConnectConnectRequest
        do {
            request = try JSONDecoder().decode(TonConnectConnectRequest.self, from: Data(json.utf8))
        } catch {
            throw TonConnectError.malformedConnectRequest("r is not a valid ConnectRequest")
        }

        guard request.manifestUrl.scheme?.lowercased() == "https" else {
            throw TonConnectError.malformedConnectRequest("manifestUrl must use https")
        }

        guard request.items.contains(where: { if case .tonAddress = $0 { return true } else { return false } }) else {
            throw TonConnectError.malformedConnectRequest("ton_addr item is required")
        }

        return request
    }

    private func parseReturnStrategy(_ raw: String?) -> TonConnectDeepLink.ReturnStrategy {
        switch raw {
        case nil, "back":
            return .back
        case "none":
            return .none
        case let custom?:
            if let url = URL(string: custom), url.scheme != nil {
                return .url(url)
            }
            return .back
        }
    }
}
