//
//  CryptoAccountDerivationIdentityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Tests for how `CryptoAccountDerivationIdentity` renders into the persistent identifier")
struct CryptoAccountDerivationIdentityTests {
    @Test("The wallet's own account renders as the bare index everything persisted before the kinds existed is keyed by")
    func cryptoAccountRendersAsBareIndex() {
        let identity = CryptoAccountDerivationIdentity(derivationIndex: 5, type: .crypto)
        let identifier = identity.toPersistentIdentifier()

        #expect(identifier == 5.toAnyHashable())
        #expect(identifier as? Int == 5)
    }

    @Test("A joint account renders with its kind spelled out and never answers as a number")
    func jointAccountRendersWithItsKind() {
        let identity = CryptoAccountDerivationIdentity(derivationIndex: 5, type: .joint)
        let identifier = identity.toPersistentIdentifier()

        #expect(identifier as? String == "joint5")
        #expect(identifier as? Int == nil)
    }

    @Test("The two kinds sharing a derivation index never render alike")
    func kindsSharingAnIndexRenderApart() {
        let cryptoAccount = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .crypto)
        let jointAccount = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)

        #expect(cryptoAccount != jointAccount)
        #expect(cryptoAccount.toPersistentIdentifier() != jointAccount.toPersistentIdentifier())
    }

    @Test("Only the wallet's own account at index zero is the main one, whatever a joint account's index says")
    func onlyCryptoAccountAtIndexZeroIsMain() {
        let cryptoAccount = CryptoAccountDerivationIdentity(derivationIndex: 0, type: .crypto)
        let jointAccount = CryptoAccountDerivationIdentity(derivationIndex: 0, type: .joint)

        #expect(AccountModelUtils.isMainAccount(cryptoAccount))
        #expect(!AccountModelUtils.isMainAccount(jointAccount))
    }
}
