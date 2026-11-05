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
