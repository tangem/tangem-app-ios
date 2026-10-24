//
//  WelcomeSceneTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("WelcomeScene")
struct WelcomeSceneTests {
    @Test("Each scene covers its own episode", arguments: [
        (0.0, WelcomeScene.store),
        (1.5, WelcomeScene.store),
        (3.09, WelcomeScene.store),
        (3.4, WelcomeScene.grow),
        (5.0, WelcomeScene.grow),
        (6.79, WelcomeScene.grow),
        (7.1, WelcomeScene.pay),
        (10.0, WelcomeScene.pay),
        (12.39, WelcomeScene.pay),
    ])
    func sceneWithinEpisode(time: TimeInterval, expected: WelcomeScene) {
        #expect(WelcomeScene.scene(at: time) == expected)
    }

    @Test("No scene while one episode gives way to the next", arguments: [
        3.1, 3.25, 3.39, // store → grow
        6.8, 6.95, 7.09, // grow → pay
        12.4, 12.9, // pay → the end of the lap
    ])
    func gapBetweenEpisodes(time: TimeInterval) {
        #expect(WelcomeScene.scene(at: time) == nil)
    }

    @Test("A position outside the lap has no scene")
    func positionOutsideLap() {
        #expect(WelcomeScene.scene(at: -1) == nil)
        #expect(WelcomeScene.scene(at: .infinity) == nil)
    }

    @Test("Every scene is reachable", arguments: WelcomeScene.allCases)
    func sceneIsReachable(scene: WelcomeScene) {
        let lap = stride(from: 0.0, to: 13.0, by: 0.01)

        #expect(lap.contains { WelcomeScene.scene(at: $0) == scene })
    }
}
