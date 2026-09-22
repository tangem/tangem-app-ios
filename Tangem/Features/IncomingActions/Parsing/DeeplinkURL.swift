//
//  DeeplinkURL.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// An incoming link of ours, read once. This is where a link stops being a `URL`: the scheme and the domain
/// are checked here, the host is normalised here, and what's left is only which kind of link it is and what
/// it carries. `nil` means the link isn't ours at all.
struct DeeplinkURL {
    let kind: Kind
    let query: DeeplinkQuery
    let absoluteString: String

    init?(url: URL) {
        guard let kind = Kind(url: url) else {
            return nil
        }

        self.kind = kind
        query = DeeplinkQuery(url: url)
        absoluteString = url.absoluteString
    }
}

// MARK: - Types

extension DeeplinkURL {
    /// A link of ours is one of two kinds, and the kind says how it names where it leads.
    /// `HostNamedDeeplink` and `PathNamedDeeplink` are the other side of these two.
    enum Kind: Equatable {
        /// `tangem://<host>?<query>` — the host is the name.
        case host(String)
        /// `https://<one of our domains>/<path>?<query>` — the first component of the path is the name, if
        /// the link names anything at all.
        case path(domain: String, components: [String])
    }
}

// MARK: - Reading the kind

private extension DeeplinkURL.Kind {
    init?(url: URL) {
        // Hosts are case-insensitive, so a link is read the same however it was typed.
        guard let host = url.host?.lowercased() else {
            return nil
        }

        if url.absoluteString.starts(with: IncomingActionConstants.appScheme) {
            self = .host(host)
            return
        }

        guard url.scheme == Constants.webScheme, IncomingActionConstants.supportedExternalLinkHosts.contains(host) else {
            return nil
        }

        // A path, when there is one, starts with a "/" component that names nothing.
        self = .path(domain: host, components: Array(url.pathComponents.dropFirst()))
    }
}

// MARK: - Constants

private extension DeeplinkURL.Kind {
    enum Constants {
        static let webScheme = "https"
    }
}
