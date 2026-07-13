//
//  FeatureToggleNamingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Enforces the feature-toggle `name` convention documented on `Feature`.
///
/// A new toggle's `name` must read `TWI-XXX_description_snake_case` or `IOS-XXX_description_snake_case`:
/// - the ticket prefix is uppercase `TWI`/`IOS` — baked into the pattern, so a lowercase prefix fails;
/// - `XXX` is the ticket number and `description` is lowercase `snake_case`;
/// - use the `IOS-` prefix when the toggle has no TWI ticket, or tracks a decomposed sub-task of one.
///
/// Toggles that predate the convention are grandfathered in `legacyToggles` and skipped, so the
/// suite only fires once a new, non-conforming toggle is introduced.
@Suite("Feature toggle naming format")
struct FeatureToggleNamingTests {
    /// Toggles created before the naming convention was introduced — intentionally exempt.
    ///
    /// Do not extend this list: a new toggle must follow the documented format instead of being
    /// parked here.
    private static let legacyToggles: Set<Feature> = [
        .disableFirmwareVersionLimit,
        .visa,
        .redesign,
        .exchangeOnlyWithinSingleAddress,
        .walletConnectBitcoin,
        .surveySparrow,
        .usdtRevokeGaslessFee,
        .yieldModuleUpdate,
        .xrplTransactionHistory,
        .deeplinkPresentationWay,
        .transactionHistoryV2,
        .tangemPayMultipleCards,
        .transfers,
        .memoValidationBeforeConfirm,
        .tangemPaySpendRedesign,
        .supportChat,
        .supportChatSwap,
        .onrampApplePayHistoryFallback,
        .mobileWalletMultiCreation,
        .approveFlowV2,
        .addAndOrganizeRedesign,
        .sendWithSwapAvailabilityCheck,
        .swapFiatCalculation,
        .swapChooseBestDEX,
        .hideStoriesInMobileWallet,
    ]

    private static var togglesToValidate: [Feature] {
        Feature.allCases.filter { !legacyToggles.contains($0) }
    }

    /// `name` must match `TWI-XXX_description_snake_case` / `IOS-XXX_description_snake_case`: an uppercase
    /// `TWI`/`IOS` prefix, the ticket number, then a lowercase `snake_case` description.
    private static let namePattern = #/(?:TWI|IOS)-[0-9]+_[a-z0-9]+(?:_[a-z0-9]+)*/#

    @Test
    func nameMatchesTicketFormat() {
        for feature in Self.togglesToValidate {
            #expect(
                feature.name.wholeMatch(of: Self.namePattern) != nil,
                """
                Feature.\(feature.rawValue) has name "\(feature.name)" that does not match \
                `TWI-XXX_description_snake_case` or `IOS-XXX_description_snake_case` (uppercase TWI/IOS \
                prefix, lowercase snake_case description). Fix its `name` in Feature.swift.
                """
            )
        }
    }
}
