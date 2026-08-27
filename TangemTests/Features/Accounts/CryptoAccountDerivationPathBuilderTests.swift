//
//  CryptoAccountDerivationPathBuilderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import enum BlockchainSdk.Blockchain
import struct TangemSdk.DerivationPath
@testable import Tangem

@Suite("Tests for how `CryptoAccountDerivationPathBuilder` places and validates the wallet's own tokens")
struct CryptoAccountDerivationPathBuilderTests {
    private let bitcoin = Blockchain.bitcoin(testnet: false)
    private let ethereum = Blockchain.ethereum(testnet: false)

    // MARK: - Placing a token

    @Test("The main account keeps the derivation a token came with, however custom it is")
    func mainAccountKeepsTheTokensOwnPath() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 0, derivationStyle: .v3)
        let customPath = try DerivationPath(rawPath: "m/44'/0'/7'/0/0")

        #expect(builder.makeDerivationPath(basedOn: customPath, for: bitcoin) == customPath)
    }

    @Test("Any other account corrects the account node and leaves the rest of the path alone")
    func otherAccountCorrectsTheAccountNodeOnly() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)
        let tokenPath = try DerivationPath(rawPath: "m/44'/0'/0'/0/9")

        let path = builder.makeDerivationPath(basedOn: tokenPath, for: bitcoin)

        #expect(path?.rawPath == "m/44'/0'/3'/0/9")
    }

    /// See Accounts-REQ-App-006 for details.
    @Test("A standard EVM path is numbered by its last node rather than the account one")
    func standardEVMPathIsNumberedByItsLastNode() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)
        let tokenPath = try DerivationPath(rawPath: "m/44'/60'/0'/0/0")

        let path = builder.makeDerivationPath(basedOn: tokenPath, for: ethereum)

        #expect(path?.rawPath == "m/44'/60'/0'/0/3")
    }

    @Test("A token that came without a path is derived from the blockchain's default one")
    func pathlessTokenIsDerivedFromTheDefaultPath() {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)

        let path = builder.makeDerivationPath(basedOn: nil, for: bitcoin)

        #expect(path?.rawPath == "m/84'/0'/3'/0/0")
    }

    @Test("A path too short to name an account is dropped for the blockchain's default one")
    func unreadablePathIsDroppedForTheDefaultOne() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)
        let shortPath = try DerivationPath(rawPath: "m/44'/0'")

        let path = builder.makeDerivationPath(basedOn: shortPath, for: bitcoin)

        #expect(path?.rawPath == "m/84'/0'/3'/0/0")
    }

    @Test("A wallet that derives nothing gives a pathless token no path at all")
    func walletWithoutDerivationGivesNoPath() {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: nil)

        #expect(builder.makeDerivationPath(basedOn: nil, for: bitcoin) == nil)
        #expect(builder.getTargetDerivationPath(for: bitcoin) == nil)
    }

    @Test("A wallet that derives nothing leaves a token the path it came with rather than stripping it")
    func walletWithoutDerivationKeepsTheTokensOwnPath() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: nil)
        // Too short to be corrected for the account, and there is no default path to fall back to
        let shortPath = try DerivationPath(rawPath: "m/44'/0'")

        #expect(builder.makeDerivationPath(basedOn: shortPath, for: bitcoin) == shortPath)
    }

    // MARK: - The path the tokens are expected at

    @Test("The account's tokens are expected at the blockchain's default path corrected for the account")
    func targetPathIsTheDefaultOneCorrected() {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)

        #expect(builder.getTargetDerivationPath(for: bitcoin)?.rawPath == "m/84'/0'/3'/0/0")
    }

    // MARK: - Validating a path

    @Test("The main account takes a token with any derivation, or with none")
    func mainAccountTakesAnything() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 0, derivationStyle: .v3)
        let anotherAccountsPath = try DerivationPath(rawPath: "m/44'/0'/7'/0/0")

        try builder.validateDerivationPath(anotherAccountsPath, for: bitcoin)
        try builder.validateDerivationPath(nil, for: bitcoin)
    }

    @Test("Any other account takes a token derived at its own number")
    func otherAccountTakesItsOwnPath() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)
        let ownPath = try DerivationPath(rawPath: "m/44'/0'/3'/0/0")

        try builder.validateDerivationPath(ownPath, for: bitcoin)
    }

    @Test("A path naming another account is turned away with both numbers named")
    func anotherAccountsPathIsTurnedAway() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)
        let anotherAccountsPath = try DerivationPath(rawPath: "m/44'/0'/1'/0/0")

        #expect(throws: AccountDerivationPathError.accountDerivationNodeMismatch(expected: 3, actual: 1)) {
            try builder.validateDerivationPath(anotherAccountsPath, for: bitcoin)
        }
    }

    @Test("A token with no path of its own has no place outside the main account")
    func pathlessTokenIsTurnedAwayFromOtherAccounts() {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)

        #expect(throws: AccountDerivationPathError.derivationPathNotFound) {
            try builder.validateDerivationPath(nil, for: bitcoin)
        }
    }

    @Test("A blockchain the accounts cannot be spread across is reported as such")
    func blockchainWithoutAccountsIsReported() throws {
        let builder = CryptoAccountDerivationPathBuilder(derivationIndex: 3, derivationStyle: .v3)
        let chia = Blockchain.chia(testnet: false)
        let chiaPath = try DerivationPath(rawPath: "m/12381'/8444'/3'/0")

        #expect(throws: AccountDerivationPathError.accountsUnavailableForBlockchain(chia.displayName)) {
            try builder.validateDerivationPath(chiaPath, for: chia)
        }
    }
}
