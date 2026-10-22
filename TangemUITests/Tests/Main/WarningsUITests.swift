//
//  WarningsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class WarningsUITests: BaseTestCase {
    func testNoAccountWarning_DisplayedOnXRPTokenDetails() {
        setAllureId(183)

        launchApp(
            tangemApiType: .mock,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.userTokensApi, initialState: Constants.State.xrp),
                ScenarioConfig(name: Constants.Scenario.rippleAccountInfo, initialState: Constants.State.accountNotFound),
                ScenarioConfig(name: Constants.Scenario.rippleAccountLines, initialState: Constants.State.accountNotFound),
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Token.xrpName)
            .validateTopUpWalletBanner(
                title: Localization.warningNoAccountTitle,
                message: Localization.noAccountGeneric(
                    Constants.Token.xrpName,
                    Constants.Token.xrpReserveAmount,
                    Constants.Token.xrpSymbol
                )
            )
    }
}

private extension WarningsUITests {
    enum Constants {
        enum Scenario {
            static let userTokensApi = "user_tokens_api"
            static let rippleAccountInfo = "ripple_account_info"
            static let rippleAccountLines = "ripple_account_lines"
        }

        enum State {
            static let xrp = "XRP"
            static let accountNotFound = "AccountNotFound"
        }

        enum Token {
            static let xrpName = "XRP Ledger"
            static let xrpSymbol = "XRP"
            static let xrpReserveAmount = "1"
        }
    }
}
