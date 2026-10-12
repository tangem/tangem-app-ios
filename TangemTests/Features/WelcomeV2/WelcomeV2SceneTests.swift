//
//  WelcomeV2SceneTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("WelcomeV2Scene")
struct WelcomeV2SceneTests {
    @Test("Each scene covers its own episode", arguments: [
        (0.0, WelcomeV2Scene.store),
        (1.5, WelcomeV2Scene.store),
        (3.09, WelcomeV2Scene.store),
        (3.4, WelcomeV2Scene.grow),
        (5.0, WelcomeV2Scene.grow),
        (6.79, WelcomeV2Scene.grow),
        (7.1, WelcomeV2Scene.pay),
        (10.0, WelcomeV2Scene.pay),
        (12.39, WelcomeV2Scene.pay),
    ])
    func sceneWithinEpisode(time: TimeInterval, expected: WelcomeV2Scene) {
        #expect(WelcomeV2Scene.scene(at: time) == expected)
    }

    @Test("No scene while one episode gives way to the next", arguments: [
        3.1, 3.25, 3.39, // store → grow
        6.8, 6.95, 7.09, // grow → pay
        12.4, 12.9, // pay → the end of the lap
    ])
    func gapBetweenEpisodes(time: TimeInterval) {
        #expect(WelcomeV2Scene.scene(at: time) == nil)
    }

    @Test("A position outside the lap has no scene")
    func positionOutsideLap() {
        #expect(WelcomeV2Scene.scene(at: -1) == nil)
        #expect(WelcomeV2Scene.scene(at: .infinity) == nil)
    }

    @Test("Every scene is reachable", arguments: WelcomeV2Scene.allCases)
    func sceneIsReachable(scene: WelcomeV2Scene) {
        let lap = stride(from: 0.0, to: 13.0, by: 0.01)

        #expect(lap.contains { WelcomeV2Scene.scene(at: $0) == scene })
    }
}
