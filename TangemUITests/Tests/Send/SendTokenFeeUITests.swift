//
//  SendTokenFeeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SendTokenFeeUITests: BaseTestCase {
    func testSendVeThor_FeeInToken_CompletesTransaction() {
        setAllureId(4907)

        let userTokensScenario = ScenarioConfig(name: "user_tokens_api", initialState: "Vechain")
        let quotesScenario = ScenarioConfig(name: "quotes_api", initialState: "Vechain")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [userTokensScenario, quotesScenario]
        )

        importHotWallet()
            .tapToken(Constants.VeThor.tokenName)
            .waitForActionButtons(requireSwapEnabled: false)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(Constants.amount)
            .tapNextButton()
            .enterDestination(Constants.VeThor.address)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .verifyNetworkFeeContains("$")
            .tapSendButton()
            .waitForDisplay()
    }

    func testSendTerraClassicUSD_FeeInToken_CompletesTransaction() {
        setAllureId(4908)

        let userTokensScenario = ScenarioConfig(name: "user_tokens_api", initialState: "Terra")
        let quotesScenario = ScenarioConfig(name: "quotes_api", initialState: "Terra")

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            scenarios: [userTokensScenario, quotesScenario]
        )

        importHotWallet()
            .tapToken(Constants.TerraClassicUSD.tokenName)
            .waitForActionButtons(requireSwapEnabled: false)
            .tapSendButton()
            .waitForDisplay()
            .enterAmount(Constants.amount)
            .tapNextButton()
            .enterDestination(Constants.TerraClassicUSD.address)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .verifyNetworkFeeContains("$")
            .tapSendButton()
            .waitForDisplay()
    }

    private enum Constants {
        static let amount = "1"

        enum VeThor {
            static let tokenName = "VeThor"
            static let address = "0x24298f15b837E5851925E18439490859e0c1F1ee"
        }

        enum TerraClassicUSD {
            static let tokenName = "TerraClassicUSD"
            static let address = "terra148dmp5ccazcwdmrcpvqz5rprnn886kemqen3tj"
        }
    }
}
