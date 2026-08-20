//
//  DynamicAddressesProviderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

@Suite("DynamicAddressesProvider Tests")
struct DynamicAddressesProviderTests {
    @Test("Bitcoin Cash used address reported as CashAddr is found in the wallet")
    func bitcoinCashCashAddrUsedAddressIsFound() throws {
        let blockchain = Blockchain.bitcoinCash
        let accountPath = "m/44'/145'/0'"
        let reportedAddress = try makeAddress(blockchain: blockchain, accountPath: accountPath, path: "0/3", type: .default)

        var wallet = try makeXPUBWallet(blockchain: blockchain, accountPath: accountPath)
        wallet.update(usedAddresses: [
            try makeUsedAddress(
                reportedAddress,
                path: "\(accountPath)/0/3",
                scriptType: .p2pkh(xpub: "xpub")
            ),
        ])

        let usedAddress = try #require(wallet.addresses.first(where: { $0.type.isUsed }))
        #expect(usedAddress.value == reportedAddress)
        #expect(usedAddress.type == .used(.default, path: "0/3"))
    }

    @Test("Bitcoin used address reported as legacy base58 is found in the wallet")
    func bitcoinLegacyUsedAddressIsFound() throws {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let accountPath = "m/44'/0'/0'"
        let reportedAddress = try makeAddress(blockchain: blockchain, accountPath: accountPath, path: "0/3", type: .legacy)

        var wallet = try makeXPUBWallet(blockchain: blockchain, accountPath: accountPath)
        wallet.update(usedAddresses: [
            try makeUsedAddress(
                reportedAddress,
                path: "\(accountPath)/0/3",
                scriptType: .p2pkh(xpub: "xpub")
            ),
        ])

        let usedAddress = try #require(wallet.addresses.first(where: { $0.type.isUsed }))
        #expect(usedAddress.value == reportedAddress)
        #expect(usedAddress.type == .used(.legacy, path: "0/3"))
    }

    @Test("Bitcoin used address reported as bech32 is found in the wallet")
    func bitcoinSegwitUsedAddressIsFound() throws {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let accountPath = "m/84'/0'/0'"
        let reportedAddress = try makeAddress(blockchain: blockchain, accountPath: accountPath, path: "0/3", type: .default)

        var wallet = try makeXPUBWallet(blockchain: blockchain, accountPath: accountPath)
        wallet.update(usedAddresses: [
            try makeUsedAddress(
                reportedAddress,
                path: "\(accountPath)/0/3",
                scriptType: .p2wpkh(xpub: "xpub")
            ),
        ])

        let usedAddress = try #require(wallet.addresses.first(where: { $0.type.isUsed }))
        #expect(usedAddress.value == reportedAddress)
        #expect(usedAddress.type == .used(.default, path: "0/3"))
    }
}

// MARK: - Private

private extension DynamicAddressesProviderTests {
    /// Test vector from https://iancoleman.io/bip39/. Any derivable extended key works here,
    /// the assertions are about which address type the provider picks.
    static var extendedPublicKey: ExtendedPublicKey {
        ExtendedPublicKey(
            publicKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
            chainCode: Data(hexString: "2C2DB3FC7AD8427443550F1F1003C0BA754D364D84998067D0B04202FDE3AD38")
        )
    }

    func makeXPUBWallet(blockchain: Blockchain, accountPath: String) throws -> Wallet {
        let accountDerivationPath = try DerivationPath(rawPath: accountPath)
        let parentDerivationPath = DerivationPath(nodes: Array(accountDerivationPath.nodes.dropLast()))

        let publicKey = Wallet.PublicKey(
            seedKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
            derivationType: .xpub(
                plain: .init(
                    path: try DerivationPath(rawPath: "\(accountPath)/0/0"),
                    extendedPublicKey: Self.extendedPublicKey
                ),
                xpub: .init(
                    child: .init(path: accountDerivationPath, extendedPublicKey: Self.extendedPublicKey),
                    parent: .init(path: parentDerivationPath, extendedPublicKey: Self.extendedPublicKey)
                )
            )
        )

        return try WalletFactory(blockchain: blockchain).makeWallet(publicKey: publicKey)
    }

    /// Derives an address the same way an explorer would report it, without going through the provider under test.
    func makeAddress(blockchain: Blockchain, accountPath: String, path: String, type: AddressType) throws -> String {
        let derivationPath = try DerivationPath(rawPath: "\(accountPath)/\(path)")
        let derivedKey = try derivationPath.nodes.suffix(2).reduce(Self.extendedPublicKey) { key, node in
            try key.derivePublicKey(node: node)
        }

        let publicKey = Wallet.PublicKey(
            seedKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
            derivationType: .plain(.init(path: derivationPath, extendedPublicKey: derivedKey))
        )

        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        return try addressService.makeAddress(for: publicKey, with: type).value
    }

    func makeUsedAddress(_ address: String, path: String, scriptType: UTXOXpubScriptType) throws -> UTXOUsedAddress {
        UTXOUsedAddress(
            address: address,
            derivationPath: try DerivationPath(rawPath: path),
            scriptType: scriptType
        )
    }
}
