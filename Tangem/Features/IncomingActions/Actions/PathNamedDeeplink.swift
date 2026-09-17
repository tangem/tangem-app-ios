//
//  PathNamedDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A destination named by the path of a link on our domain: `https://tangem.com/<pathSegment>/…`.
///
/// Independent of `HostNamedDeeplink`, so a destination can be reachable by both: an invite to a joint
/// account arrives as `tangem://joint-account-invite?id` from the app and as `/joint-account/join/{id}` from
/// a link someone was sent — which is why such a destination is listed under both.
protocol PathNamedDeeplink {
    /// The first component of the path, which is what the destination is looked up by. The rest of the shape
    /// is the destination's own business.
    static var pathSegment: String { get }

    /// `nil` when the link doesn't become this destination: the path starts with the segment but is of
    /// another shape — `/news` is the news section, not an article — or it doesn't carry what the destination
    /// needs. Either way the link stays the page it is, and is opened as one.
    static func action(from link: DeeplinkURL) -> DeeplinkNavigationAction?
}
