//
//  FeedScrollCoordinatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
@testable import Tangem

@Suite("Feed scroll coordinator")
@MainActor
struct FeedScrollCoordinatorTests {
    @Test("Switching tabs restores the scroll the feed keeps for them")
    func keepsScrollBetweenTabs() {
        let scroll = makeSUT()

        _ = scroll.scrollTarget(forTab: "crypto", viewportHeight: 600, pinTabs: false, chipsPinned: false)
        scroll.report(offset: 250, tabID: "crypto")

        let target = scroll.scrollTarget(forTab: "earn", viewportHeight: 600, pinTabs: false, chipsPinned: false)

        guard case .jump(let anchor, let shift) = target else {
            Issue.record("Switching to a tab scrolled elsewhere has to move the feed, got \(String(describing: target))")
            return
        }

        #expect(anchor == UnitPoint(x: 0, y: -116.0 / 599))
        #expect(shift == -134)
    }

    @Test("A feed reopened from the top no longer restores where the tab it showed was left")
    func resetForgetsTheVisibleTabScroll() {
        let scroll = makeSUT()

        _ = scroll.scrollTarget(forTab: "crypto", viewportHeight: 600, pinTabs: false, chipsPinned: false)
        scroll.report(offset: 250, tabID: "crypto")
        scroll.reset()

        _ = scroll.scrollTarget(forTab: "earn", viewportHeight: 600, pinTabs: false, chipsPinned: false)
        scroll.report(offset: 0, tabID: "earn")

        #expect(scroll.scrollTarget(forTab: "crypto", viewportHeight: 600, pinTabs: false, chipsPinned: false) == nil)
    }

    @Test("The widgets reporting nothing to measure yet leave the header they were last seen at")
    func emptyWidgetsMeasurementKeepsTheHeader() {
        // The widgets are measured as empty before their content arrives; where the next tab lands must not
        // depend on whether that measurement was seen.
        #expect(anchorAfterSwitchingTabs(reportingEmptyWidgets: true) == anchorAfterSwitchingTabs(reportingEmptyWidgets: false))
    }

    private func makeSUT() -> FeedScrollCoordinator {
        let scroll = FeedScrollCoordinator()
        scroll.report(widgets: 100)
        return scroll
    }

    private func anchorAfterSwitchingTabs(reportingEmptyWidgets: Bool) -> UnitPoint? {
        let scroll = makeSUT()

        _ = scroll.scrollTarget(forTab: "crypto", viewportHeight: 600, pinTabs: false, chipsPinned: false)
        scroll.report(offset: 250, tabID: "crypto")

        if reportingEmptyWidgets {
            scroll.report(widgets: 0)
        }

        guard case .jump(let anchor, _) = scroll.scrollTarget(forTab: "earn", viewportHeight: 600, pinTabs: false, chipsPinned: false) else {
            Issue.record("Switching tabs must restore the scroll without a vertical animation")
            return nil
        }

        return anchor
    }
}
