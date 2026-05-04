//
//  XPUBUtilsTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

@Suite("XPUBUtils Tests")
struct XPUBUtilsTests {
    let sut = XPUBUtils()

    // MARK: - generateXPUB

    /// Test vector from https://iancoleman.io/bip39/
    @Test("Generate XPUB for BTC mainnet m/44'/0'/0'/0")
    func generateXPUBForBTC() throws {
        let key = Wallet.PublicKey.XPUBKey(
            child: .init(
                path: try DerivationPath(rawPath: "m/44'/0'/0'/0"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
                    chainCode: Data(hexString: "2C2DB3FC7AD8427443550F1F1003C0BA754D364D84998067D0B04202FDE3AD38")
                )
            ),
            parent: .init(
                path: try DerivationPath(rawPath: "m/44'/0'/0'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "02FB16DF58DF3C8FDB128CEE3159EF552ED0DDF77451D401C74CD8B1F768246E4C"),
                    chainCode: Data(hexString: "F2FAA12902156F4F3054384CFE11DBB3DA57DCB8F0DACB39DD5632F871F20A83")
                )
            )
        )

        let xpub = try sut.generateXPUB(key: key, isTestnet: false)

        #expect(xpub == "xpub6E8jCqdYZcAaj9ZovPA1xiTRSu7brzzamw4yD8PsQjxYZS1sj4GfiGvhXyzBbqXiyh9MX2UhzY8X3M2CWPMmENccMbVvbrySE6EbE9ieHWJ")
    }

    /// Test vector from https://iancoleman.io/bip39/
    @Test("Generate XPUB with hardened child index m/44'/0'/1'/10'")
    func generateXPUBWithHardenedIndex() throws {
        let key = Wallet.PublicKey.XPUBKey(
            child: .init(
                path: try DerivationPath(rawPath: "m/44'/0'/1'/10'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "038B35FD52B5318B7C44712810636040D7BD703CF93F843871754A35F78D777135"),
                    chainCode: Data(hexString: "B1EC31F392C0A09F566111656AFE1BB61C120514D776E257CDED55850153E5EE")
                )
            ),
            parent: .init(
                path: try DerivationPath(rawPath: "m/44'/0'/1'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "02265527CC18902C44496979E9C7B758DAB947E0987262B65F14C9C077873E9630"),
                    chainCode: Data(hexString: "CD5F9816192A61FD3C5AB7439B20D4DA90CA9818ACFE170A11BB0F7BA4DEC21E")
                )
            )
        )

        let xpub = try sut.generateXPUB(key: key, isTestnet: false)

        #expect(xpub == "xpub6FAqNyRZorqRKQyQCJqsCd264fh1Wiv4d42Myic4Tu5HfgGyhn4CH1MxjTZUQFoUv5UKAAkRdrWHGZWyaYDrjjycN1jxsycC7J7cBe7G2tx")
    }

    // MARK: - xpubDerivationPaths

    @Test("BIP-84 path m/84'/0'/0'/0/0 returns correct child and parent")
    func xpubDerivationPathsBIP84() throws {
        let path = try DerivationPath(rawPath: "m/84'/0'/0'/0/0")

        let result = try sut.xpubDerivationPaths(for: path)

        let expectedChild = try DerivationPath(rawPath: "m/84'/0'/0'")
        let expectedParent = try DerivationPath(rawPath: "m/84'/0'")
        #expect(result.child == expectedChild, "Child should drop last 2 nodes")
        #expect(result.parent == expectedParent, "Parent should drop last 3 nodes")
    }

    @Test("BIP-44 path m/44'/0'/0'/0/0 returns correct child and parent")
    func xpubDerivationPathsBIP44() throws {
        let path = try DerivationPath(rawPath: "m/44'/0'/0'/0/0")

        let result = try sut.xpubDerivationPaths(for: path)

        let expectedChild = try DerivationPath(rawPath: "m/44'/0'/0'")
        let expectedParent = try DerivationPath(rawPath: "m/44'/0'")
        #expect(result.child == expectedChild)
        #expect(result.parent == expectedParent)
    }

    @Test("BIP-49 path m/49'/0'/0'/0/0 returns correct child and parent")
    func xpubDerivationPathsBIP49() throws {
        let path = try DerivationPath(rawPath: "m/49'/0'/0'/0/0")

        let result = try sut.xpubDerivationPaths(for: path)

        let expectedChild = try DerivationPath(rawPath: "m/49'/0'/0'")
        let expectedParent = try DerivationPath(rawPath: "m/49'/0'")
        #expect(result.child == expectedChild)
        #expect(result.parent == expectedParent)
    }

    @Test("Path with non-zero address index m/84'/0'/0'/0/5")
    func xpubDerivationPathsNonZeroIndex() throws {
        let path = try DerivationPath(rawPath: "m/84'/0'/0'/0/5")

        let result = try sut.xpubDerivationPaths(for: path)

        let expectedChild = try DerivationPath(rawPath: "m/84'/0'/0'")
        let expectedParent = try DerivationPath(rawPath: "m/84'/0'")
        #expect(result.child == expectedChild)
        #expect(result.parent == expectedParent)
    }

    @Test("Change chain path m/84'/0'/0'/1/0 returns same account-level paths")
    func xpubDerivationPathsChangeChain() throws {
        let path = try DerivationPath(rawPath: "m/84'/0'/0'/1/0")

        let result = try sut.xpubDerivationPaths(for: path)

        let expectedChild = try DerivationPath(rawPath: "m/84'/0'/0'")
        let expectedParent = try DerivationPath(rawPath: "m/84'/0'")
        #expect(result.child == expectedChild)
        #expect(result.parent == expectedParent)
    }

    // MARK: - xpubDerivationPaths errors

    @Test("Path with 3 nodes throws wrongDerivationPath")
    func xpubDerivationPathsTooShort() throws {
        let path = try DerivationPath(rawPath: "m/84'/0'/0'")

        #expect(throws: XPUBUtils.Error.wrongDerivationPath) {
            try sut.xpubDerivationPaths(for: path)
        }
    }

    @Test("Path with 4 nodes throws wrongDerivationPath")
    func xpubDerivationPathsFourNodes() throws {
        let path = try DerivationPath(rawPath: "m/84'/0'/0'/0")

        #expect(throws: XPUBUtils.Error.wrongDerivationPath) {
            try sut.xpubDerivationPaths(for: path)
        }
    }

    @Test("Path with 6 nodes throws wrongDerivationPath")
    func xpubDerivationPathsTooLong() throws {
        let path = try DerivationPath(rawPath: "m/84'/0'/0'/0/0/0")

        #expect(throws: XPUBUtils.Error.wrongDerivationPath) {
            try sut.xpubDerivationPaths(for: path)
        }
    }
}
