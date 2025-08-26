//
//  MobileWalletAddressesTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemMobileWalletSdk
@testable import Tangem
import BlockchainSdk
import TangemSdk
import TangemFoundation

class MobileWalletAddressesTests {
    let userWalletId = UserWalletId(with: Data(hexString: "0374d0f81f42ddfe34114d533e95e6ae5fe6ea271c96f1fa505199fdc365ae9720"))

    @Test
    func testAddresses() async throws {
        let mnemonic = try Mnemonic(with: "tiny escape drive pupil flavor endless love walk gadget match filter luxury")

        let walletInfo = try await MobileWalletInitializer().initializeWallet(mnemonic: mnemonic, passphrase: nil)

        // Delete the wallet to clean up the keychain
        try? CommonMobileWalletSdk().delete(walletIDs: [userWalletId])

        let data = try jsonData(for: "test_addresses")

        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        let seedKeys: [EllipticCurve: Data] = walletInfo.keys.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let config = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
        try config.supportedBlockchains.forEach { blockchain in

            let keyInfo = try #require(walletInfo.keys.filter { $0.curve == blockchain.curve }.first)

            let curve = try #require(seedKeys[blockchain.curve])

            let derivationType: Wallet.PublicKey.DerivationType?
            switch blockchain {
            case .cardano:
                let derivationPath = try #require(blockchain.derivationPath(for: .v3))
                let publicKey = try #require(keyInfo.derivedKeys[derivationPath])

                let secondDerivationPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)
                let secondPublicKey = try #require(keyInfo.derivedKeys[secondDerivationPath])
                derivationType = .double(
                    first: .init(
                        path: derivationPath,
                        extendedPublicKey: publicKey
                    ),
                    second: .init(path: secondDerivationPath, extendedPublicKey: secondPublicKey)
                )
            case .chia:
                derivationType = nil
            default:
                let derivationPath = try #require(blockchain.derivationPath(for: .v3))
                let publicKey = try #require(keyInfo.derivedKeys[derivationPath])

                derivationType = .plain(.init(path: derivationPath, extendedPublicKey: publicKey))
            }

            let walletPublicKey = Wallet.PublicKey(
                seedKey: curve,
                derivationType: derivationType
            )

            let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

            let address = try addressService.makeAddress(for: walletPublicKey, with: .default)

            #expect(json[blockchain.networkId] == address.value)
        }
    }

    private func jsonData(for fileName: String) throws -> Data {
        let bundle = Bundle(for: MobileWalletAddressesTests.self)
        let path = try #require(bundle.path(forResource: fileName, ofType: "json"))
        let string = try String(contentsOfFile: path)
        let jsonData = try #require(string.data(using: .utf8))
        return jsonData
    }
}
