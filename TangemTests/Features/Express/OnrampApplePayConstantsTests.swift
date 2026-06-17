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
    private static let mercuryoCountryCode = "LT"

    @Test("Production build always returns production config, regardless of stored merchant type")
    func productionBuildIgnoresStoredType() {
        let withSandboxStored = OnrampApplePayConstants.config(
            forProviderId: "mercuryo",
            isProduction: true,
            nonProductionMerchantType: .sandbox
        )
        let withProductionStored = OnrampApplePayConstants.config(
            forProviderId: "mercuryo",
            isProduction: true,
            nonProductionMerchantType: .production
        )

        #expect(withSandboxStored?.merchantIdentifier == Self.mercuryoProductionId)
        #expect(withSandboxStored?.countryCode == Self.mercuryoCountryCode)
        #expect(withProductionStored?.merchantIdentifier == Self.mercuryoProductionId)
        #expect(withProductionStored?.countryCode == Self.mercuryoCountryCode)
    }

    @Test("Non-production build with .sandbox returns sandbox config")
    func nonProductionSandbox() {
        let config = OnrampApplePayConstants.config(
            forProviderId: "mercuryo",
            isProduction: false,
            nonProductionMerchantType: .sandbox
        )

        #expect(config?.merchantIdentifier == Self.mercuryoSandboxId)
        #expect(config?.countryCode == Self.mercuryoCountryCode)
    }

    @Test("Non-production build with .production returns production config")
    func nonProductionWithProductionType() {
        let config = OnrampApplePayConstants.config(
            forProviderId: "mercuryo",
            isProduction: false,
            nonProductionMerchantType: .production
        )

        #expect(config?.merchantIdentifier == Self.mercuryoProductionId)
        #expect(config?.countryCode == Self.mercuryoCountryCode)
    }

    @Test("Unknown provider id returns nil")
    func unknownProviderReturnsNil() {
        let prod = OnrampApplePayConstants.config(
            forProviderId: "unknown-provider",
            isProduction: true,
            nonProductionMerchantType: .sandbox
        )
        let sandbox = OnrampApplePayConstants.config(
            forProviderId: "unknown-provider",
            isProduction: false,
            nonProductionMerchantType: .sandbox
        )

        #expect(prod == nil)
        #expect(sandbox == nil)
    }

    @Test("Provider id lookup is case-insensitive")
    func providerIdCaseInsensitive() {
        let upper = OnrampApplePayConstants.config(
            forProviderId: "MERCURYO",
            isProduction: true,
            nonProductionMerchantType: .sandbox
        )
        let mixed = OnrampApplePayConstants.config(
            forProviderId: "MeRcUrYo",
            isProduction: false,
            nonProductionMerchantType: .sandbox
        )

        #expect(upper?.merchantIdentifier == Self.mercuryoProductionId)
        #expect(upper?.countryCode == Self.mercuryoCountryCode)
        #expect(mixed?.merchantIdentifier == Self.mercuryoSandboxId)
        #expect(mixed?.countryCode == Self.mercuryoCountryCode)
    }

    @Test("ApplePayMerchantType raw values stable for UserDefaults persistence")
    func rawValuesStable() {
        #expect(ApplePayMerchantType.production.rawValue == "production")
        #expect(ApplePayMerchantType.sandbox.rawValue == "sandbox")
        #expect(ApplePayMerchantType.allCases.count == 2)
    }
}
