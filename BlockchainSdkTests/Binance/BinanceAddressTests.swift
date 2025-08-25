@testable import BlockchainSdk
import TangemSdk
import Testing
import enum WalletCore.CoinType

struct BinanceAddressTests {
    private let addressesUtility = AddressServiceManagerUtility()
    private let service: AddressService
    private let testnetService: AddressService

    init() {
        service = AddressServiceFactory(blockchain: .binance(testnet: false)).makeAddressService()
        testnetService = AddressServiceFactory(blockchain: .binance(testnet: true)).makeAddressService()
    }

    @Test
    func defaultAddressGeneration() throws {
        // given
        let blockchain = Blockchain.binance(testnet: false)

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
        // when
        let addr_dec = try testnetService.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        let addr_comp = try testnetService.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)

        // then
        #expect(addr_dec.value == addr_comp.value)
        #expect(addr_dec.localizedName == addr_comp.localizedName)
        #expect(addr_dec.type == addr_comp.type)
        #expect(addr_dec.value == "tbnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5ehnavcf") // [REDACTED_TODO_COMMENT]
    }

    @Test(arguments: [true, false])
    func inavalidCurveGeneration_throwsError(isTestNet: Bool) async throws {
        #expect(throws: (any Error).self) {
            try testnetService.makeAddress(from: Keys.AddressesKeys.edKey)
        }
    }

    @Test(arguments: ["bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc"])
    func addressValidation_validAddresses(addressHex: String) {
        let addressValidator = service
        #expect(addressValidator.validate(addressHex))
    }

    @Test(arguments: ["bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcz"])
    func addressValidation_invalidAddresses(addressHex: String) {
        let addressValidator = service
        #expect(!addressValidator.validate(addressHex))
    }
}
