import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing
import WalletCore

struct TezosAddressTests {
    private static let curves: [EllipticCurve] = [.ed25519, .ed25519_slip0010]

    @Test
    func defaultAddressGeneration_secp256k1Curve() throws {
        // given
        let service = makeAddressService(curve: .secp256k1)

        // when
        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        // then
        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.value == "tz2SdMQ72FP39GB1Cwyvs2BPRRAMv9M6Pc6B")
    }

    @Test
    func inavalidCurveGeneration_whenTryToGeneratedFromEdKey_thenThrowsError() async throws {
        let service = makeAddressService(curve: .secp256k1)
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: curves)
    func defaultAddressGeneration_edCurve(curve: EllipticCurve) throws {
        // given
        let service = makeAddressService(curve: curve)

        // when
        let address = try service.makeAddress(from: Keys.AddressesKeys.edKey)

        // then
        #expect(address.localizedName == AddressType.default.defaultLocalizedName)
        #expect(address.value == "tz1VS42nEFHoTayE44ZKANQWNhZ4QbWFV8qd")
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test(arguments: curves)
    func inavalidCurveGeneration_whenTryToGeneratedFromSecp256k1Key_thenThrowsError(curve: EllipticCurve) async throws {
        let service = makeAddressService(curve: curve)
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test(arguments: [
        "tz1d1qQL3mYVuiH4JPFvuikEpFwaDm85oabM",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        Self.curves.forEach {
            let addressValidator = makeAddressService(curve: $0)
            #expect(addressValidator.validate(addressHex))
        }
    }

    @Test(arguments: [
        "tz1eZwq8b5cvE2bPKokatLkVMzkxz24z3AAAA",
        "1tzeZwq8b5cvE2bPKokatLkVMzkxz24zAAAAA",
    ])
    func addressValidation_invalidAddresses(addressHex: String) {
        Self.curves.forEach {
            let addressValidator = makeAddressService(curve: $0)
            #expect(!addressValidator.validate(addressHex))
        }
    }

    private func makeAddressService(curve: EllipticCurve) -> AddressService {
        AddressServiceFactory(blockchain: .tezos(curve: curve)).makeAddressService()
    }
}
