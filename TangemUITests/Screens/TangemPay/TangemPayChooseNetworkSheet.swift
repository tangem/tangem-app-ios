//
//  TangemPayChooseNetworkSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayChooseNetworkSheet: ScreenBase<TangemPayChooseNetworkSheetElement> {
    private lazy var fastOptionsTitle = staticText(.fastOptionsTitle)
    private lazy var otherOptionsTitle = staticText(.otherOptionsTitle)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the Choose network sheet") { _ in
            waitAndAssertTrue(fastOptionsTitle, timeout: .networkRequest, "Fast options section should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyFastOptions(_ networks: [TangemPayNetwork]) -> Self {
        verifySection(
            named: Localization.tangempayChooseNetworkFastWay,
            title: fastOptionsTitle,
            nextSectionTitle: otherOptionsTitle,
            networks: networks
        )
    }

    @discardableResult
    func verifyOtherOptions(_ networks: [TangemPayNetwork]) -> Self {
        verifySection(named: Localization.tangempayChooseNetworkOtherWays, title: otherOptionsTitle, nextSectionTitle: nil, networks: networks)
    }

    @discardableResult
    func verifyNetworkSubtitle(_ network: TangemPayNetwork, contains text: String) -> Self {
        XCTContext.runActivity(named: "Verify '\(network.displayName)' row mentions '\(text)'") { _ in
            let predicate = NSPredicate(
                format: "identifier == %@ AND label CONTAINS[c] %@",
                TangemPayAccessibilityIdentifiers.chooseNetworkSheetRow(chainId: network.chainId),
                text
            )
            waitAndAssertTrue(
                app.descendants(matching: .any).matching(predicate).firstMatch,
                timeout: .conditional,
                "'\(network.displayName)' row should mention '\(text)'. Actual: '\(row(network).label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapNetworkExpectingReceive(_ network: TangemPayNetwork) -> TangemPayMultichainReceiveSheet {
        XCTContext.runActivity(named: "Tap '\(network.displayName)' expecting the receive sheet") { _ in
            row(network).waitAndTap()
            return TangemPayMultichainReceiveSheet(app)
        }
    }

    @discardableResult
    func tapNetworkExpectingOtherNetworks(_ network: TangemPayNetwork) -> TangemPayOtherNetworksSheet {
        XCTContext.runActivity(named: "Tap '\(network.displayName)' expecting the Other networks sheet") { _ in
            row(network).waitAndTap()
            return TangemPayOtherNetworksSheet(app)
        }
    }

    @discardableResult
    func tapNetworkExpectingActivation(_ network: TangemPayNetwork) -> Self {
        XCTContext.runActivity(named: "Tap not issued network '\(network.displayName)'") { _ in
            row(network).waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyCloseButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the Choose network sheet close button") { _ in
            waitAndAssertTrue(closeButton, "Close button should be displayed")
            return self
        }
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the Choose network sheet") { _ in
            closeButton.waitAndTap()
            return TangemPayMainScreen(app)
        }
    }

    private func row(_ network: TangemPayNetwork) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: TangemPayAccessibilityIdentifiers.chooseNetworkSheetRow(chainId: network.chainId))
            .firstMatch
    }

    /// Rows live in one scroll view, so section membership is read off the vertical position between the section titles.
    @discardableResult
    private func verifySection(
        named name: String,
        title: XCUIElement,
        nextSectionTitle: XCUIElement?,
        networks: [TangemPayNetwork]
    ) -> Self {
        XCTContext.runActivity(named: "Verify \(name) lists \(networks.map(\.displayName))") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "\(name) section title should be displayed")

            let sectionTop = title.frame.maxY
            // The whole sheet renders at once, so a missing next section means this one runs to the bottom.
            var sectionBottom = CGFloat.greatestFiniteMagnitude
            if let nextSectionTitle, nextSectionTitle.exists {
                sectionBottom = nextSectionTitle.frame.minY
            }

            var previousRowTop = sectionTop
            for network in networks {
                let element = row(network)
                waitAndAssertTrue(element, "'\(network.displayName)' should be listed in \(name)")
                XCTAssertTrue(
                    element.label.contains(network.displayName),
                    "'\(network.displayName)' row should carry its network name. Actual: '\(element.label)'"
                )

                let rowTop = element.frame.minY
                XCTAssertTrue(
                    rowTop > previousRowTop && rowTop < sectionBottom,
                    "'\(network.displayName)' should follow the previous \(name) row and stay inside the section"
                )
                previousRowTop = rowTop
            }
            return self
        }
    }
}

enum TangemPayChooseNetworkSheetElement: String, UIElement {
    case fastOptionsTitle
    case otherOptionsTitle
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .fastOptionsTitle:
            TangemPayAccessibilityIdentifiers.chooseNetworkSheetFastOptionsTitle
        case .otherOptionsTitle:
            TangemPayAccessibilityIdentifiers.chooseNetworkSheetOtherOptionsTitle
        case .closeButton:
            TangemPayAccessibilityIdentifiers.chooseNetworkSheetCloseButton
        }
    }
}
