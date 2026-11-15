//
//  MobileWalletLimitTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Mobile wallet limit")
struct MobileWalletLimitTests {
    typealias Wallets = ConfiguredUserWalletModelStub

    @Test("The limit is reached at five mobile wallets", arguments: zip([4, 5], [false, true]))
    func limitIsReachedAtFiveMobileWallets(count: Int, isReached: Bool) {
        #expect(MobileWalletLimit.isReached(in: Wallets.mobile(count: count)) == isReached)
    }

    @Test("Cards do not count towards the limit")
    func cardsAreNotCounted() {
        #expect(!MobileWalletLimit.isReached(in: Wallets.mobile(count: 4) + Wallets.cards(count: 3)))
    }

    @Test("A social wallet counts towards the limit")
    func socialWalletIsCounted() {
        #expect(MobileWalletLimit.isReached(in: Wallets.mobile(count: 4) + [Wallets.social()]))
    }

    @Test("A sixth mobile wallet hits the limit while a card does not", arguments: zip([true, false], [true, false]))
    func limitAppliesOnlyToMobileWallets(isMobileCandidate: Bool, isReached: Bool) {
        let candidate = isMobileCandidate ? Wallets.mobile() : Wallets.card()

        #expect(MobileWalletLimit.isReached(for: candidate, in: Wallets.mobile(count: 5)) == isReached)
    }

    @Test("A fifth mobile wallet is still allowed")
    func fifthMobileWalletIsAllowed() {
        #expect(!MobileWalletLimit.isReached(for: Wallets.mobile(), in: Wallets.mobile(count: 4)))
    }

    @Test("Only mobile wallets are listed")
    func mobileWalletsLeaveCardsOut() {
        let wallets = Wallets.mobile(count: 2) + Wallets.cards(count: 3) + [Wallets.social()]

        #expect(MobileWalletLimit.mobileWallets(in: wallets).count == 3)
    }
}
