//
//  DeeplinkRegistrationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// A destination is looked up by the name it is registered under, and nothing else says whether that name is
/// the one it declares.
@Suite("Deeplink destination registration")
struct DeeplinkRegistrationTests {
    @Test("Every destination is registered under the host it declares")
    func hostsMatchTheirDestination() {
        for (host, destination) in DeeplinkNavigationAction.destinationsNamedByHost {
            #expect(host == destination.host, "\(destination) answers to \(destination.host), registered as \(host)")
        }
    }

    @Test("Every destination is registered under the path component it declares")
    func pathSegmentsMatchTheirDestination() {
        for (segment, destination) in DeeplinkNavigationAction.destinationsNamedByPath {
            #expect(segment == destination.pathSegment, "\(destination) answers to \(destination.pathSegment), registered as \(segment)")
        }
    }

    @Test("Every name is written the way a link carries it")
    func namesAreLowercase() {
        let names = Array(DeeplinkNavigationAction.destinationsNamedByHost.keys)
            + Array(DeeplinkNavigationAction.destinationsNamedByPath.keys)

        for name in names {
            #expect(name == name.lowercased(), "\(name) would never match: names are read in lower case")
        }
    }
}
