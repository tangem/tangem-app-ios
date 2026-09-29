//
//  TonConnectManifest.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `tonconnect-manifest.json` (`spec/manifest.md`). Unknown top-level fields are ignored by design.
public struct TonConnectManifest: Codable, Equatable, Sendable {
    public let url: URL
    public let name: String
    public let iconUrl: URL
    public let termsOfUseUrl: URL?
    public let privacyPolicyUrl: URL?

    public init(url: URL, name: String, iconUrl: URL, termsOfUseUrl: URL? = nil, privacyPolicyUrl: URL? = nil) {
        self.url = url
        self.name = name
        self.iconUrl = iconUrl
        self.termsOfUseUrl = termsOfUseUrl
        self.privacyPolicyUrl = privacyPolicyUrl
    }

    /// Decodes a manifest body and applies the content rules from `spec/manifest.md`
    /// and the domain-binding rules from `spec/connect.md`.
    public static func decode(from body: Data) throws -> TonConnectManifest {
        let manifest: TonConnectManifest
        do {
            manifest = try JSONDecoder().decode(TonConnectManifest.self, from: body)
        } catch {
            throw TonConnectError.manifestContentError("not a valid manifest JSON")
        }

        _ = try manifest.appDomain()

        guard !manifest.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TonConnectError.manifestContentError("name is empty")
        }

        guard manifest.iconUrl.scheme?.lowercased() == "https" else {
            throw TonConnectError.manifestContentError("iconUrl must use https")
        }

        return manifest
    }

    /// `AppDomain` used in `ton_proof` and `signData` signatures: the host of `url`.
    ///
    /// Per the domain-binding rules the host must contain at least one `.` with non-empty labels on both
    /// sides; bare names (`tonkeeper`, `localhost`) are reserved for native integrations and rejected.
    public func appDomain() throws -> String {
        guard url.scheme?.lowercased() == "https" else {
            throw TonConnectError.manifestContentError("url must use https")
        }

        guard let host = url.host?.lowercased(), Self.isValidAppDomain(host) else {
            throw TonConnectError.manifestContentError("url host is not a valid dApp domain")
        }

        return host
    }

    static func isValidAppDomain(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2 else { return false }
        return labels.allSatisfy { !$0.isEmpty }
    }
}
