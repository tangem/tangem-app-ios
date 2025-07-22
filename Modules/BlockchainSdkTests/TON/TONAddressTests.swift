//
//  TONAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
@testable import BlockchainSdk
import Testing

struct TONAddressTests {
    private static let curves = [EllipticCurve.ed25519, .ed25519_slip0010]
    private let addressesUtility = AddressServiceManagerUtility()

    @Test(arguments: curves)
    func defaultAddressGeneration(curve: EllipticCurve) throws {
        let blockchain = Blockchain.ton(curve: curve, testnet: false)
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let walletPubkey1 = Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb")
        let expectedAddress1 = "UQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrdpr"
        #expect(try addressService.makeAddress(from: walletPubkey1).value == expectedAddress1)

        let walletPubkey2 = Data(hex: "258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5")
        let expectedAddress2 = "UQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eL1z"
        #expect(try addressService.makeAddress(from: walletPubkey2).value == expectedAddress2)

        let walletPubkey3 = Data(hex: "f42c77f931bea20ec5d0150731276bbb2e2860947661245b2319ef8133ee8d41")
        let expectedAddress3 = "UQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts4DV"
        #expect(try addressService.makeAddress(from: walletPubkey3).value == expectedAddress3)

        let walletPubkey4 = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        #expect((try? addressService.makeAddress(from: walletPubkey4)) == nil)

        let walletPubkey5 = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        #expect((try? addressService.makeAddress(from: walletPubkey5)) == nil)

        #expect((try? addressService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)) == nil)

        #expect((try? addressService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)) == nil)

        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: walletPubkey1, for: blockchain) == expectedAddress1)
    }

    @Test(arguments: [
        "UQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrdpr",
        "UQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eL1z",
        "UQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts4DV",
        "0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae",
        "0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3",
    ])
    func validAddresses(address: String) {
        Self.curves.forEach {
            let blockchain = Blockchain.ton(curve: $0, testnet: false)
            let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            #expect(addressService.validate(address))
        }
    }

    @Test(arguments: [
        "8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"
    ])
    func invalidAddresses(address: String) {
        Self.curves.forEach {
            let blockchain = Blockchain.ton(curve: $0, testnet: false)
            let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            #expect(!addressService.validate(address))
        }
    }
}
