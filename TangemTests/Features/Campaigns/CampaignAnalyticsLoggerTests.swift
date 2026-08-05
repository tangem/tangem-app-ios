//
//  CampaignAnalyticsLoggerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("CampaignAnalyticsLogger", .tags(.campaigns))
struct CampaignAnalyticsLoggerTests {
    @Test("Each campaign type reports its own analytics parameter value")
    func campaignTypesReportDistinctParameterValues() {
        #expect(CampaignAnalyticsLogger(campaign: .whaleSwap).campaignValue == .cashback)
        #expect(CampaignAnalyticsLogger(campaign: .reactivation).campaignValue == .reactivation)
    }
}
