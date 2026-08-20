//
//  CommonPolymarketOwnerAddressProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemSdk
@testable import Tangem

@Suite
struct CommonPolymarketOwnerAddressProviderTests {
    private static let derivedPublicKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private static let derivedAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"

    private static let walletPublicKey = Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    private static let chainCode = Data(repeating: 0x11, count: 32)

    @Test(arguments: [true, false])
    func theOwnerAddressIsReturnedEvenIfTheCacheDropsTheWrite(cachePersists: Bool) async throws {
        let provider = Self.makeProvider(
            repository: Self.makeRepository(derivedKey: nil, persists: cachePersists),
            result: .success(Self.derivationResult)
        )

        #expect(try await provider.deriveOwnerAddress() == Self.derivedAddress)
    }

    @Test
    func anAlreadyDerivedKeyResolvesWithoutDerivingAgain() async throws {
        let provider = Self.makeProvider(
            repository: Self.makeRepository(derivedKey: Self.extendedPublicKey),
            result: .success([:])
        )

        #expect(provider.getOwnerAddress() == Self.derivedAddress)
        #expect(try await provider.deriveOwnerAddress() == Self.derivedAddress)
    }

    @Test
    func aDerivationThatProducedNothingIsNotReportedAsAMissingWallet() async {
        let provider = Self.makeProvider(repository: Self.makeRepository(derivedKey: nil), result: .success([:]))

        await #expect(throws: PolymarketDerivationError.keyNotDerived) {
            try await provider.deriveOwnerAddress()
        }
    }

    @Test
    func aWalletWithoutSecp256k1CannotOnboard() async {
        let repository = KeysRepositoryTestsMock(keys: [Self.makeKeyInfo(curve: .ed25519, derivedKey: nil)])
        let provider = Self.makeProvider(repository: repository, result: .success(Self.derivationResult))

        #expect(provider.getOwnerAddress() == nil)
        await #expect(throws: PolymarketDerivationError.missingWallet) {
            try await provider.deriveOwnerAddress()
        }
    }

    @Test
    func aWalletWithoutHDDerivationCannotOnboard() async {
        let provider = Self.makeProvider(
            repository: Self.makeRepository(derivedKey: nil),
            result: .success(Self.derivationResult),
            areHDWalletsSupported: false
        )

        await #expect(throws: PolymarketDerivationError.derivationUnsupported) {
            try await provider.deriveOwnerAddress()
        }
    }

    @Test(arguments: CardFailure.allCases)
    func cardFailuresKeepTheirRetryability(failure: CardFailure) async {
        let provider = Self.makeProvider(repository: Self.makeRepository(derivedKey: nil), result: .failure(failure.sdkError))

        await #expect(throws: failure.expectedError) {
            try await provider.deriveOwnerAddress()
        }
    }

    @Test
    func aFailureThatIsNotTheCardIsNotBlamedOnTheCard() async {
        struct NetworkishError: Error {}
        let provider = Self.makeProvider(repository: Self.makeRepository(derivedKey: nil), result: .failure(NetworkishError()))

        await #expect(throws: PolymarketDerivationError.unknown) {
            try await provider.deriveOwnerAddress()
        }
    }
}

// MARK: - Scenarios

extension CommonPolymarketOwnerAddressProviderTests {
    enum CardFailure: CaseIterable, Sendable {
        case userCancelled
        case walletNotFound
        case otherCardError

        var sdkError: TangemSdkError {
            switch self {
            case .userCancelled: .userCancelled
            case .walletNotFound: .walletNotFound
            case .otherCardError: .cardError
            }
        }

        var expectedError: PolymarketDerivationError {
            switch self {
            case .userCancelled: .cancelled
            case .walletNotFound: .missingWallet
            case .otherCardError: .cardFailed
            }
        }
    }
}

// MARK: - Fixtures

private extension CommonPolymarketOwnerAddressProviderTests {
    static var extendedPublicKey: ExtendedPublicKey {
        ExtendedPublicKey(publicKey: derivedPublicKey, chainCode: chainCode)
    }

    static var derivationResult: DerivationResult {
        [walletPublicKey: DerivedKeys(keys: [PolymarketUtilities.derivationPath: extendedPublicKey])]
    }

    static func makeProvider(
        repository: KeysRepositoryTestsMock,
        result: Result<DerivationResult, Error>,
        areHDWalletsSupported: Bool = true
    ) -> CommonPolymarketOwnerAddressProvider {
        CommonPolymarketOwnerAddressProvider(
            keysRepository: repository,
            keysDerivingInteractor: KeysDerivingTestsMock(result: result),
            areHDWalletsSupported: areHDWalletsSupported
        )
    }

    static func makeRepository(derivedKey: ExtendedPublicKey?, persists: Bool = true) -> KeysRepositoryTestsMock {
        KeysRepositoryTestsMock(keys: [makeKeyInfo(curve: .secp256k1, derivedKey: derivedKey)], persists: persists)
    }

    static func makeKeyInfo(curve: EllipticCurve, derivedKey: ExtendedPublicKey?) -> KeyInfo {
        KeyInfo(
            publicKey: walletPublicKey,
            chainCode: chainCode,
            curve: curve,
            isImported: false,
            derivedKeys: derivedKey.map { [PolymarketUtilities.derivationPath: $0] } ?? [:]
        )
    }
}

// MARK: - Doubles

private final class KeysDerivingTestsMock: KeysDeriving {
    private let result: Result<DerivationResult, Error>

    init(result: Result<DerivationResult, Error>) {
        self.result = result
    }

    var requiresCard: Bool { true }

    func deriveKeys(derivations: [Data: [DerivationPath]], completion: @escaping (Result<DerivationResult, Error>) -> Void) {
        completion(result)
    }
}
