//
//  SendFeeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SendFeeUITests: BaseTestCase {
    func testNetworkFeeSelectorNotDisplayed_ForPolkadotFixedFeeNetwork() {
        setAllureId(4868)

        let polkadotScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Polkadot"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [polkadotScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Network.polkadot)
            .tapActionButton(.send)

        SendScreen(app)
            .waitForDisplay()
            .enterAmount(Constants.Amount.polkadot)
            .tapNextButton()
            .enterDestination(Constants.Address.polkadot)
            .tapNextButtonToSummary()
            .tapFeeBlock()

        SendSummaryScreen(app)
            .waitForNetworkFeeSelectorUnavailable()
    }

    func testNetworkFeeSelectorDisplaysOptions_ForEthereum() {
        setAllureId(4869)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Network.ethereum)
            .tapActionButton(.send)

        let sendSummaryScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount(Constants.Amount.ethereum)
            .tapNextButton()
            .enterDestination(Constants.Address.ethereum)
            .tapNextButtonToSummary()

        sendSummaryScreen
            .tapFeeBlock()
            .waitForDisplay(cryptoSymbol: "ETH", fiatSymbol: "$")
            .selectCustom()
            .waitForCustomFields()
    }

    func testNetworkFeeSelectorCustomOption_ForBitcoin() {
        setAllureId(4870)

        let bitcoinScenario = ScenarioConfig(
            name: "bitcoin_utxo",
            initialState: "Balance"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [bitcoinScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Network.bitcoin)
            .tapActionButton(.send)

        let sendSummaryScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount(Constants.Amount.bitcoin)
            .tapNextButton()
            .enterDestination(Constants.Address.bitcoin)
            .tapNextButtonToSummary()

        let feeSelectorScreen = sendSummaryScreen
            .tapFeeBlock()
            .waitForDisplay(cryptoSymbol: "BTC", fiatSymbol: "$")

        feeSelectorScreen
            .selectCustom()
            .verifyCustomOptionSelected()
            .waitForBitcoinCustomFields()
            .waitForBitcoinCustomFieldsPrefilled()
            .verifyMaxFeeFieldNotEditable()
            .verifySatoshiPerByteFieldEditable()

        feeSelectorScreen
            .enterSatoshiPerByte(Constants.Fee.satoshiPerByte)

        let maxFeeFiatValue = feeSelectorScreen.getMaxFeeFiatValue()
        XCTAssertFalse(maxFeeFiatValue.isEmpty, "Max Fee fiat value should not be empty after entering Satoshi per vbyte")

        feeSelectorScreen
            .tapFeeSelectorDoneToSummary()
            .waitForNetworkFeeAmount(maxFeeFiatValue)
    }

    func testNetworkFeeSelectorDisplaysOptions_ForVeThor() {
        setAllureId(4871)

        let veChainScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Vechain"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Vechain"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [veChainScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Network.vethor)
            .tapActionButton(.send)

        let sendSummaryScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount(Constants.Amount.vethor)
            .tapNextButton()
            .enterDestination(Constants.Address.vethor)
            .tapNextButtonToSummary()

        sendSummaryScreen
            .waitForDisplay(checkValidatorBlock: false)
            .verifyNetworkFeeContains("$")
            .tapFeeBlock()
            .waitForDisplay(cryptoSymbol: "VTHO", fiatSymbol: "$", includeCustom: false)
    }

    func testNetworkFeeSelectorNotDisplayed_ForTerraClassicUSD() {
        setAllureId(4906)

        let terraClassicScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Terra"
        )
        let quotesScenario = ScenarioConfig(
            name: "quotes_api",
            initialState: "Terra"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [terraClassicScenario, quotesScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Network.terraClassicUSD)
            .tapActionButton(.send)

        let sendSummaryScreen = SendScreen(app)
            .waitForDisplay()
            .enterAmount(Constants.Amount.terraClassicUSD)
            .tapNextButton()
            .enterDestination(Constants.Address.terraClassicUSD)
            .tapNextButtonToSummary()

        sendSummaryScreen
            .waitForDisplay(checkValidatorBlock: false)
            .verifyNetworkFeeContains("$")
            .tapFeeBlock()

        SendSummaryScreen(app)
            .waitForNetworkFeeSelectorUnavailable()
    }

    private enum Constants {
        enum Network {
            static let polkadot = "Polkadot"
            static let ethereum = "Ethereum"
            static let bitcoin = "Bitcoin"
            static let vethor = "VeThor"
            static let terraClassicUSD = "TerraClassicUSD"
        }

        enum Address {
            static let polkadot = "143TfgFYAFfM86LRzt4UcFNU3KosxCndBCVz2U5HCxpLidKZ"
            static let ethereum = "0x24298f15b837E5851925E18439490859e0c1F1ee"
            static let bitcoin = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
            static let vethor = "0x24298f15b837E5851925E18439490859e0c1F1ee"
            static let terraClassicUSD = "terra148dmp5ccazcwdmrcpvqz5rprnn886kemqen3tj"
        }

        enum Amount {
            static let polkadot = "1"
            static let ethereum = "0.8"
            static let bitcoin = "0.001"
            static let vethor = "1"
            static let terraClassicUSD = "1"
        }

        enum Fee {
            static let satoshiPerByte = "10"
        }
    }
}
