//
//  MobileWalletLimitUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Mobile wallet limit restriction")
struct MobileWalletLimitUtilTests {
    typealias Wallets = ConfiguredUserWalletModelStub

    @Test("Below the limit every way of adding a mobile wallet is allowed", arguments: [MobileWalletLimitUtil.Addition.create, .import, .socialLogin])
    func belowLimitAllowsAddition(addition: MobileWalletLimitUtil.Addition) async {
        await withWallets(Wallets.mobile(count: 4)) { sut in
            #expect(sut.restriction(for: addition) == nil)
        }
    }

    @Test("Five mobile wallets block create, import and social login", arguments: [MobileWalletLimitUtil.Addition.create, .import, .socialLogin])
    func limitBlocksAddition(addition: MobileWalletLimitUtil.Addition) async {
        await withWallets(Wallets.mobile(count: 5)) { sut in
            #expect(sut.restriction(for: addition) == .mobileWalletsLimitReached(addition))
        }
    }

    @Test("Cards do not count towards the mobile wallet limit")
    func cardsAreNotCounted() async {
        await withWallets(Wallets.mobile(count: 4) + Wallets.cards(count: 3)) { sut in
            #expect(sut.restriction(for: .create) == nil)
        }
    }

    @Test("Only one social wallet is allowed while other additions stay available")
    func socialWalletAllowsOnlyOne() async {
        await withWallets(Wallets.mobile(count: 2) + [Wallets.social()]) { sut in
            #expect(sut.restriction(for: .socialLogin) == .socialWalletAlreadyAdded)
            #expect(sut.restriction(for: .create) == nil)
            #expect(sut.restriction(for: .import) == nil)
        }
    }

    @Test("The mobile wallet limit wins over the social wallet restriction")
    func limitWinsOverSocialRestriction() async {
        await withWallets(Wallets.mobile(count: 4) + [Wallets.social()]) { sut in
            #expect(sut.restriction(for: .socialLogin) == .mobileWalletsLimitReached(.socialLogin))
        }
    }

    @Test("A social wallet counts towards the mobile wallet limit")
    func socialWalletIsCounted() async {
        await withWallets(Wallets.mobile(count: 4) + [Wallets.social()]) { sut in
            #expect(sut.restriction(for: .create) == .mobileWalletsLimitReached(.create))
        }
    }

    @Test("Storing a sixth mobile wallet is refused while a card can still be stored")
    func storingChecksOnlyMobileWallets() {
        let wallets = Wallets.mobile(count: 5)

        #expect(MobileWalletLimit.isReached(for: Wallets.mobile(), in: wallets))
        #expect(!MobileWalletLimit.isReached(for: Wallets.card(), in: wallets))
    }

    @Test("Storing a fifth mobile wallet is allowed")
    func storingBelowLimitIsAllowed() {
        #expect(!MobileWalletLimit.isReached(for: Wallets.mobile(), in: Wallets.mobile(count: 4)))
    }

    @Test("The limit is reached at five mobile wallets regardless of cards")
    func limitIsReachedAtFiveMobileWallets() {
        #expect(MobileWalletLimit.isReached(in: Wallets.mobile(count: 5)))
        #expect(!MobileWalletLimit.isReached(in: Wallets.mobile(count: 4) + Wallets.cards(count: 3)))
    }
}

// MARK: - Helpers

private extension MobileWalletLimitUtilTests {
    func withWallets(_ wallets: [UserWalletModel], _ body: (MobileWalletLimitUtil) -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: wallets)
            defer { InjectedValues[\.userWalletRepository] = previousRepository }

            body(MobileWalletLimitUtil())
        }
    }
}
