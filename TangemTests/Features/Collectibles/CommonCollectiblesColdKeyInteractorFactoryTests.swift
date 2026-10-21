//
//  CommonCollectiblesColdKeyInteractorFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemCollectibles
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CommonCollectiblesColdKeyInteractorFactory")
final class CommonCollectiblesColdKeyInteractorFactoryTests: LeakTrackingTestSuite {
    typealias SUT = CommonCollectiblesColdKeyInteractorFactory

    @Test("Without a provider the unavailable interactor is served")
    func servesUnavailableWithoutProvider() {
        let sut = makeSUT()

        #expect(sut.makeInteractor() is UnavailableCollectiblesColdKeyInteractor)
    }

    @Test("Serves the provider's interactor whether the provider came at init or later", arguments: [true, false])
    func servesProviderInteractor(isProvidedAtInit: Bool) {
        let interactor = InteractorStub()
        let provider = ProviderStub(interactor: interactor)
        let sut = makeSUT(provider: isProvidedAtInit ? provider : nil)

        if !isProvidedAtInit {
            sut.configure(with: provider)
        }

        withExtendedLifetime(provider) {
            #expect(sut.makeInteractor() as? InteractorStub === interactor)
        }
    }

    @Test("Configuring again switches to the new provider")
    func reconfigureSwitchesProvider() {
        let firstProvider = ProviderStub(interactor: InteractorStub())
        let secondInteractor = InteractorStub()
        let secondProvider = ProviderStub(interactor: secondInteractor)
        let sut = makeSUT(provider: firstProvider)

        sut.configure(with: secondProvider)

        withExtendedLifetime((firstProvider, secondProvider)) {
            #expect(sut.makeInteractor() as? InteractorStub === secondInteractor)
        }
    }

    @Test("A provider that went away makes the factory fall back to the unavailable interactor")
    func releasedProviderFallsBackToUnavailable() {
        let sut = makeSUT()

        configureWithTemporaryProvider(sut)

        #expect(sut.makeInteractor() is UnavailableCollectiblesColdKeyInteractor)
    }
}

// MARK: - Helpers

private extension CommonCollectiblesColdKeyInteractorFactoryTests {
    func makeSUT(provider: ProviderStub? = nil) -> SUT {
        trackForMemoryLeaks(SUT(interactorProvider: provider))
    }

    func configureWithTemporaryProvider(_ sut: SUT) {
        sut.configure(with: ProviderStub(interactor: InteractorStub()))
    }
}

// MARK: - Doubles

private final class ProviderStub: CollectiblesColdKeyInteractorProvider {
    let collectiblesColdKeyInteractor: any CollectiblesColdKeyInteractor

    init(interactor: any CollectiblesColdKeyInteractor) {
        collectiblesColdKeyInteractor = interactor
    }
}

private final class InteractorStub: CollectiblesColdKeyInteractor {
    func derive<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output {
        try await work.run(signer: self)
    }

    func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        Data()
    }
}
