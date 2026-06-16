//
//  OnrampApplePayConstantsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("OnrampApplePayConstants")
struct OnrampApplePayConstantsTests {
    private static let mercuryoProductionId = "merchant.mercuryo.com.tangem.tangem"
    private static let mercuryoSandboxId = "merchant.sandbox.mercuryo.com.tangem.tangem"

    @Test("Production build always returns production merchant id, regardless of stored merchant type")
    func productionBuildIgnoresStoredType() {
        let withSandboxStored = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "mercuryo",
            isProduction: true,
            nonProductionMerchantType: .sandbox
        )
        let withProductionStored = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "mercuryo",
            isProduction: true,
            nonProductionMerchantType: .production
        )

        #expect(withSandboxStored == Self.mercuryoProductionId)
        #expect(withProductionStored == Self.mercuryoProductionId)
    }

    @Test("Non-production build with .sandbox returns sandbox merchant id")
    func nonProductionSandbox() {
        let id = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "mercuryo",
            isProduction: false,
            nonProductionMerchantType: .sandbox
        )

        #expect(id == Self.mercuryoSandboxId)
    }

    @Test("Non-production build with .production returns production merchant id")
    func nonProductionWithProductionType() {
        let id = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "mercuryo",
            isProduction: false,
            nonProductionMerchantType: .production
        )

        #expect(id == Self.mercuryoProductionId)
    }

    @Test("Unknown provider id returns nil")
    func unknownProviderReturnsNil() {
        let prod = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "unknown-provider",
            isProduction: true,
            nonProductionMerchantType: .sandbox
        )
        let sandbox = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "unknown-provider",
            isProduction: false,
            nonProductionMerchantType: .sandbox
        )

        #expect(prod == nil)
        #expect(sandbox == nil)
    }

    @Test("Provider id lookup is case-insensitive")
    func providerIdCaseInsensitive() {
        let upper = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "MERCURYO",
            isProduction: true,
            nonProductionMerchantType: .sandbox
        )
        let mixed = OnrampApplePayConstants.merchantIdentifier(
            forProviderId: "MeRcUrYo",
            isProduction: false,
            nonProductionMerchantType: .sandbox
        )

        #expect(upper == Self.mercuryoProductionId)
        #expect(mixed == Self.mercuryoSandboxId)
    }

    @Test("ApplePayMerchantType raw values stable for UserDefaults persistence")
    func rawValuesStable() {
        #expect(ApplePayMerchantType.production.rawValue == "production")
        #expect(ApplePayMerchantType.sandbox.rawValue == "sandbox")
        #expect(ApplePayMerchantType.allCases.count == 2)
    }
}
