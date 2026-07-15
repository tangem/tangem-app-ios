//
//  ReferralUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class ReferralUITests: BaseTestCase {
    func testReferralProgramFlow_DisplayConditionsAndParticipateButton() {
        setAllureId(3647)
        let walletName = "Wallet"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: walletName)
            .openReferralProgram()
            .verifyReferralScreenDisplayed()
    }

    func testReferral_TokenAndBlockchainAddingAfterParticipation() {
        setAllureId(3630)
        let walletName = "Wallet"
        let tokenNetwork = "Tron"
        let token = "Tether"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyTokenNotVisible(tokenNetwork)
            .verifyTokenNotVisible(token)
            .openDetails()
            .openWalletSettings(for: walletName)
            .openReferralProgram()
            .tapParticipateButton()
            .verifyPersonalCodeTitleDisplayed()
            .tapBackButton(to: CardSettingsScreen.self)
            .tapBackButton(to: DetailsScreen.self)
            .tapBackButton(to: MainScreen.self)
            .verifyTokenVisible(tokenNetwork)
            .verifyTokenVisible(token)
    }

    func testReferral_TokenAddingAfterParticipation() {
        setAllureId(10098)
        let walletScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "Tron"
        )
        let walletName = "Wallet"
        let token = "Tether"

        launchApp(
            tangemApiType: .mock,
            scenarios: [
                walletScenario,
            ]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyTokenNotVisible(token)
            .openDetails()
            .openWalletSettings(for: walletName)
            .openReferralProgram()
            .tapParticipateButton()
            .verifyPersonalCodeTitleDisplayed()
            .tapBackButton(to: CardSettingsScreen.self)
            .tapBackButton(to: DetailsScreen.self)
            .tapBackButton(to: MainScreen.self)
            .verifyTokenVisible(token)
    }

    func testReferral_ReferralUnavailableForNoWalletCards() {
        setAllureId(3629)
        let cardsWithoutReferral: [CardMockAccessibilityIdentifiers] = [
            .four12, .twin, .nodl, .xrpNote, .xlmBird, .s2c,
        ]

        for card in cardsWithoutReferral {
            XCTContext.runActivity(named: "Card \(card.rawValue)") { _ in
                launchApp(tangemApiType: .mock)
                CreateWalletSelectorScreen(app)
                    .scanMockWallet(name: card)
                    .openDetails()
                    .openWalletSettings()
                    .verifyReferralUnavailable()
            }
        }
    }

    func testReferral_VerifyWalletDerivation() {
        setAllureId(3636)
        let token = "Tron"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings()
            .openReferralProgram()
            .tapParticipateButton()
            .tapBackButton(to: CardSettingsScreen.self)
            .tapBackButton(to: DetailsScreen.self)
            .openEnvironmentSetup()
            .openAddressesInfo()
            .verifyDerivationPath(forNetwork: token, expected: "m/44'/195'/0'/0/0")
    }
}
