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

    /// Upper bound on a manifest body. Real manifests are a few hundred bytes; the limit keeps a hostile
    /// `manifestUrl` from feeding the JSON decoder megabytes.
    public static let maxByteCount = 64 * 1024

    /// Decodes a manifest body and applies the content rules from `spec/manifest.md`
    /// and the domain-binding rules from `spec/connect.md`.
    public static func decode(from body: Data) throws -> TonConnectManifest {
        guard body.count <= maxByteCount else {
            throw TonConnectError.manifestContentError("manifest exceeds \(maxByteCount) bytes")
        }

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

    /// `true` when the manifest was fetched from the domain it claims (`manifestUrl` host equals `url`
    /// host or is a subdomain of it).
    ///
    /// The spec lets a dApp host its manifest anywhere, and CDN / GitHub-hosted manifests are common, so a
    /// mismatch is not an error. It is, however, the exact shape of a `ton_proof` phishing attempt: a
    /// manifest served from `attacker.example` that claims `url: https://real-dapp.example` makes the
    /// wallet sign a login proof for the real dApp's domain with the attacker's nonce. The UI should show
    /// the serving host prominently (and warn) when this returns `false`.
    public func isServedFromAppDomain(manifestUrl: URL) -> Bool {
        guard let appDomain = try? appDomain(), let servingHost = manifestUrl.host?.lowercased() else {
            return false
        }
        return servingHost == appDomain || servingHost.hasSuffix("." + appDomain)
    }

    static func isValidAppDomain(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2, labels.allSatisfy({ !$0.isEmpty }) else { return false }
        // A dotted IPv4 literal is not a domain name.
        return !labels.allSatisfy { $0.allSatisfy(\.isNumber) }
    }
}
