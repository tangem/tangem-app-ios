//
//  AccountsAnalyticsBuildersTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for the account parameters of analytics events")
struct AccountsAnalyticsBuildersTests {
    @Test("A paired builder names the kind of the source account next to its derivation", arguments: [
        (AccountType.crypto, "Crypto"),
        (AccountType.joint, "Joint"),
        (AccountType.collectibles, "Collectibles"),
    ])
    func sourceAccountIsNamedByKind(type: AccountType, kind: String) {
        let params = PairedAccountAnalyticsBuilder(role: .source)
            .setDerivationIdentity(CryptoAccountDerivationIdentity(derivationIndex: 2, type: type))
            .build()

        #expect(params == [.accountDerivationFrom: "2", .accountTypeFrom: kind])
    }

    @Test("A paired builder names the kind of the destination account next to its derivation")
    func destinationAccountIsNamedByKind() {
        let params = PairedAccountAnalyticsBuilder(role: .destination)
            .setDerivationIdentity(CryptoAccountDerivationIdentity(derivationIndex: 0, type: .joint))
            .build()

        #expect(params == [.accountDerivationTo: "0", .accountTypeTo: "Joint"])
    }

    @Test("The type builder reports the kind of account alone", arguments: [
        (AccountType.crypto, "Crypto"),
        (AccountType.joint, "Joint"),
        (AccountType.collectibles, "Collectibles"),
    ])
    func typeBuilderReportsTheKindAlone(type: AccountType, kind: String) {
        let params = AccountTypeAnalyticsBuilder()
            .setDerivationIdentity(CryptoAccountDerivationIdentity(derivationIndex: 1, type: type))
            .build()

        #expect(params == [.accountType: kind])
    }

    @Test("An account that never told its identity reports nothing")
    func unknownIdentityReportsNothing() {
        #expect(PairedAccountAnalyticsBuilder(role: .source).build().isEmpty)
        #expect(AccountTypeAnalyticsBuilder().build().isEmpty)
    }
}
