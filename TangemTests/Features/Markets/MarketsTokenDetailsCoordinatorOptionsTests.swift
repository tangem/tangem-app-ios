//
//  MarketsTokenDetailsCoordinatorOptionsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketsTokenDetailsCoordinator.Options")
struct MarketsTokenDetailsCoordinatorOptionsTests {
    @Test(
        "Portfolio actions follow the presentation style by default",
        arguments: [
            (MarketsTokenDetailsPresentationStyle.marketsSheet, true),
            (.addFundsSheet, true),
            (.navigationStack, false),
            (.fullScreenCover, false),
        ]
    )
    func defaultsFollowStyle(style: MarketsTokenDetailsPresentationStyle, expected: Bool) {
        let options = MarketsTokenDetailsCoordinator.Options(info: .deeplinkStub(tokenId: Constants.tokenId), style: style)

        #expect(options.showsPortfolioActions == expected)
    }

    @Test("An explicit value overrides the style")
    func explicitValueOverridesStyle() {
        let options = MarketsTokenDetailsCoordinator.Options(
            info: .deeplinkStub(tokenId: Constants.tokenId),
            style: .navigationStack,
            showsPortfolioActions: true
        )

        #expect(options.showsPortfolioActions)
    }

    @Test("The token chart deeplink opens in a navigation stack and follows the toggle", arguments: [true, false])
    func tokenChartDeeplink(isToggleEnabled: Bool) {
        var requestedFeatures: [Feature] = []

        let options = MarketsTokenDetailsCoordinator.Options.tokenChartDeeplink(tokenId: Constants.tokenId) { feature in
            requestedFeatures.append(feature)
            return isToggleEnabled
        }

        #expect(requestedFeatures == [.tokenChartAddToPortfolio])
        #expect(options.info.id == Constants.tokenId)
        #expect(options.style == .navigationStack)
        #expect(!options.isDeeplinkMode)
        #expect(options.showsPortfolioActions == isToggleEnabled)
    }
}

private extension MarketsTokenDetailsCoordinatorOptionsTests {
    enum Constants {
        static let tokenId = "stellar"
    }
}
