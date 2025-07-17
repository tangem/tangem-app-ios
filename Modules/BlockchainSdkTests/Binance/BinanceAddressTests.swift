@testable import BlockchainSdk
import TangemSdk
import Testing

struct BinanceAddressTests {
    private let blockchain = Blockchain.binance(testnet: false)

    @Test
    func defaultAddressGeneration() throws {
        // given
        let service = BinanceAddressService(testnet: false)
        let addressesUtility = AddressServiceManagerUtility()

        // when
        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        // then
        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_dec.value == "bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc")
        try #expect(addressesUtility.makeTrustWalletAddress(publicKey: Keys.AddressesKeys.secpDecompressedKey, for: blockchain) == addr_dec.value)
    }

    @Test
    func testnetAddressGeneration() throws {
        // given
        let service = BinanceAddressService(testnet: true)

        // when
        let addr_dec = try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        // then
        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_dec.value == "tbnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5ehnavcf") // [REDACTED_TODO_COMMENT]
    }

    @Test(.serialized, arguments: [true, false])
    func invalidCurveGeneration_throwsError(isTestNet: Bool) async throws {
        let service = BinanceAddressService(testnet: true)
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(.serialized, arguments: [
        "bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc",
    ])
    func addressValidation_validAddresses(addressHex: String) {
        let walletCoreAddressValidator: AddressValidator
        walletCoreAddressValidator = WalletCoreAddressService(coin: .binance)
        let addressValidator = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        #expect(walletCoreAddressValidator.validate(addressHex))
        #expect(addressValidator.validate(addressHex))
    }
}
