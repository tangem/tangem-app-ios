//
//  TokenDetailsReceiveQRCodeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TokenDetailsReceiveQRCodeUITests: BaseTestCase {
    func testReceiveQRCodeEncodesDisplayedAddress_Bitcoin() {
        setAllureId(4947)

        launchApp(tangemApiType: .mock, clearStorage: true, features: [.redesign: true])

        openReceive(token: "Bitcoin")
            .assertBothAddressTypesEncodeDisplayedAddressAndDiffer()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_Litecoin() {
        setAllureId(10215)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [ScenarioConfig(name: "user_tokens_api", initialState: "Litecoin")]
        )

        openReceive(token: "Litecoin", useHotWallet: true)
            .assertBothAddressTypesEncodeDisplayedAddressAndDiffer()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_XDC() {
        setAllureId(10220)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [ScenarioConfig(name: "user_tokens_api", initialState: "XDC")]
        )

        openReceive(token: "XDC Network", useHotWallet: true)
            .assertBothAddressTypesEncodeDisplayedAddressAndDiffer()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_Decimal() {
        setAllureId(10214)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [ScenarioConfig(name: "user_tokens_api", initialState: "Decimal")]
        )

        openReceive(token: "Decimal Smart Chain", useHotWallet: true)
            .assertBothAddressTypesEncodeDisplayedAddressAndDiffer()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_Cosmos() {
        setAllureId(10218)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "Cosmos"),
                ScenarioConfig(name: "networks_providers", initialState: "AppTransfersNetworks"),
            ]
        )

        openReceive(token: "Cosmos")
            .tapShowQRCode(.segwit)
            .assertQRCodeEncodesDisplayedAddress()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_Kaspa() {
        setAllureId(10219)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "Kaspa"),
                ScenarioConfig(name: "networks_providers", initialState: "AppTransfersNetworks"),
                ScenarioConfig(name: "kaspa_utxo", initialState: "more_than_84"),
            ]
        )

        openReceive(token: "Kaspa")
            .tapShowQRCode(.segwit)
            .assertQRCodeEncodesDisplayedAddress()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_Hedera() {
        setAllureId(10216)

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
            features: [.redesign: true],
            scenarios: [
                ScenarioConfig(name: "user_tokens_api", initialState: "Hedera"),
                ScenarioConfig(name: "networks_providers", initialState: "AppTransfersNetworks"),
            ]
        )

        openReceive(token: "Hedera")
            .tapShowQRCode(.segwit)
            .assertQRCodeEncodesDisplayedAddress()
    }

    func testReceiveQRCodeEncodesDisplayedAddress_Ethereum() {
        setAllureId(10217)

        launchApp(tangemApiType: .mock, clearStorage: true, features: [.redesign: true])

        openReceive(token: "Ethereum")
            .tapShowQRCode(.segwit)
            .assertQRCodeEncodesDisplayedAddress()
    }

    private func openReceive(token: String, useHotWallet: Bool = false) -> ReceiveTemplatesSheet {
        // Tokens outside the mock card's fixed derivations need a seed-based hot wallet.
        let mainScreen = useHotWallet
            ? importHotWallet()
            : CreateWalletSelectorScreen(app).scanMockWallet(name: .wallet2)

        return mainScreen
            .generateMissingAddressesIfNeeded()
            .tapToken(token)
            // tapReceiveButton resolves either the direct Receive button or the Add Funds group.
            .tapReceiveButton()
            .tapUnderstoodIfNeeded()
    }
}
