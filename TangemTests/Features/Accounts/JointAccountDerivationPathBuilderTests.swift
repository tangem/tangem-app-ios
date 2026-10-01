//
//  JointAccountDerivationPathBuilderTests.swift
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

@Suite("Tests for how `JointAccountDerivationPathBuilder` names and validates the account's single path")
struct JointAccountDerivationPathBuilderTests {
    private let builder = JointAccountDerivationPathBuilder(derivationIndex: 3)
    private let ethereum = Blockchain.ethereum(testnet: false)
    private let bitcoin = Blockchain.bitcoin(testnet: false)

    // MARK: - Making the path

    @Test("The account's path is made from its index alone, whatever path a token came with")
    func pathIsMadeFromTheIndexAlone() throws {
        let tokenPath = try DerivationPath(rawPath: "m/44'/60'/5'/0/9")

        let madeFromTokenPath = builder.makeDerivationPath(basedOn: tokenPath, for: ethereum)
        let madeFromNothing = builder.makeDerivationPath(basedOn: nil, for: ethereum)

        // A part of the contract with the backend, which syncs the token list between the members by this path
        #expect(madeFromTokenPath?.rawPath == "m/44'/60'/888888'/0/3")
        #expect(madeFromNothing?.rawPath == "m/44'/60'/888888'/0/3")
    }

    @Test("A blockchain outside the EVM networks gets no path: the account cannot hold anything of it")
    func nonEVMBlockchainGetsNoPath() {
        #expect(builder.makeDerivationPath(basedOn: nil, for: bitcoin) == nil)
        #expect(builder.getTargetDerivationPath(for: bitcoin) == nil)
    }

    @Test("The tokens are expected exactly where they are derived")
    func targetPathIsTheAccountsOwn() {
        let targetPath = builder.getTargetDerivationPath(for: ethereum)

        #expect(targetPath?.rawPath == "m/44'/60'/888888'/0/3")
    }

    // MARK: - Validating a path

    @Test("The account's own path passes the validation")
    func ownPathPassesValidation() throws {
        let ownPath = try DerivationPath(rawPath: "m/44'/60'/888888'/0/3")

        try builder.validateDerivationPath(ownPath, for: ethereum)
    }

    @Test("A joint path of another account is turned away with both numbers named")
    func anotherAccountsPathIsTurnedAway() throws {
        let anotherAccountsPath = try DerivationPath(rawPath: "m/44'/60'/888888'/0/8")

        #expect(throws: AccountDerivationPathError.accountDerivationNodeMismatch(expected: 3, actual: 8)) {
            try builder.validateDerivationPath(anotherAccountsPath, for: ethereum)
        }
    }

    @Test("An EVM path of the wallet's own accounts is not mistaken for a joint one, index positions notwithstanding")
    func cryptoAccountsEVMPathIsNotMistakenForAJointOne() throws {
        // A standard EVM path keeps the account's number at the very same node a joint path keeps its own,
        // so telling them apart takes the whole path, not the node
        let cryptoAccountsPath = try DerivationPath(rawPath: "m/44'/60'/5'/0/3")

        #expect(throws: AccountDerivationPathError.notAJointAccountDerivationPath(ethereum.displayName)) {
            try builder.validateDerivationPath(cryptoAccountsPath, for: ethereum)
        }
    }

    @Test("A token with no path of its own has no place in the account")
    func pathlessTokenIsTurnedAway() {
        #expect(throws: AccountDerivationPathError.derivationPathNotFound) {
            try builder.validateDerivationPath(nil, for: ethereum)
        }
    }

    @Test("A curve with no derivation support is turned away before the path is even read")
    func curveWithoutDerivationIsTurnedAway() throws {
        let chia = Blockchain.chia(testnet: false)
        let ownPath = try DerivationPath(rawPath: "m/44'/60'/888888'/0/3")

        #expect(throws: AccountDerivationPathError.derivationNotSupported(chia.displayName)) {
            try builder.validateDerivationPath(ownPath, for: chia)
        }
    }

    @Test("A network the account cannot hold anything of is named as the reason")
    func unsupportedNetworkIsNamedAsTheReason() throws {
        // Bitcoin derives at a curve that supports derivation, so the refusal is about the network alone
        let bitcoinPath = try DerivationPath(rawPath: "m/44'/0'/3'/0/0")

        #expect(throws: AccountDerivationPathError.jointAccountsUnavailableForBlockchain(bitcoin.displayName)) {
            try builder.validateDerivationPath(bitcoinPath, for: bitcoin)
        }
    }

    @Test("An EVM network outside the supported ones is turned away, though the path could be made for it")
    func unsupportedEVMNetworkIsTurnedAway() throws {
        let gnosis = Blockchain.gnosis
        let ownPath = try DerivationPath(rawPath: "m/44'/60'/888888'/0/3")

        #expect(throws: AccountDerivationPathError.jointAccountsUnavailableForBlockchain(gnosis.displayName)) {
            try builder.validateDerivationPath(ownPath, for: gnosis)
        }
    }

    @Test("A testnet of a supported network passes the validation just like its mainnet")
    func supportedNetworksTestnetPassesValidation() throws {
        let ownPath = try DerivationPath(rawPath: "m/44'/60'/888888'/0/3")

        try builder.validateDerivationPath(ownPath, for: .polygon(testnet: true))
    }

    @Test("A path too short to name an account is reported as such")
    func shortPathIsReported() throws {
        let shortPath = try DerivationPath(rawPath: "m/44'/60'")

        let expectedError = AccountDerivationPathError.insufficientNodes(
            required: 5,
            actual: 2,
            blockchain: ethereum.displayName
        )

        #expect(throws: expectedError) {
            try builder.validateDerivationPath(shortPath, for: ethereum)
        }
    }
}
