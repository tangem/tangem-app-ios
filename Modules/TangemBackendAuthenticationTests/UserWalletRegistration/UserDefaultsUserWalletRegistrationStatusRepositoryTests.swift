//
//  UserDefaultsUserWalletRegistrationStatusRepositoryTests.swift
//  Modules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class UserDefaultsUserWalletRegistrationStatusRepositoryTests: LeakTrackingTestSuite {
    private let suiteName = "com.tangem.backendAuthentication.tests.\(UUID().uuidString)"

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    @Test
    func retrieveReturnsFalseByDefault() async throws {
        let (sut, _) = try makeSUT()

        #expect(await sut.retrieve(id: Self.firstWalletID) == false)
    }

    @Test(arguments: [true, false])
    func retrieveReflectsPersistedValue(isRegistered: Bool) async throws {
        let (sut, _) = try makeSUT()

        await sut.persist(isRegistered: isRegistered, id: Self.firstWalletID)

        #expect(await sut.retrieve(id: Self.firstWalletID) == isRegistered)
    }

    @Test
    func retrieveReadsFromTheUnderlyingUserDefaultsInstance() async throws {
        let (sut, userDefaults) = try makeSUT()

        userDefaults.set([Self.firstWalletID.hashedStringValue(message: Self.key)], forKey: Self.key)

        #expect(await sut.retrieve(id: Self.firstWalletID) == true)
    }

    @Test
    func persistDoesNotAffectOtherIDs() async throws {
        let (sut, _) = try makeSUT()

        await sut.persist(isRegistered: true, id: Self.firstWalletID)

        #expect(await sut.retrieve(id: Self.secondWalletID) == false)
    }

    @Test
    func persistPreservesPreviouslyRegisteredIDs() async throws {
        let (sut, _) = try makeSUT()

        await sut.persist(isRegistered: true, id: Self.firstWalletID)
        await sut.persist(isRegistered: true, id: Self.secondWalletID)

        #expect(await sut.retrieve(id: Self.firstWalletID) == true)
        #expect(await sut.retrieve(id: Self.secondWalletID) == true)
    }

    @Test
    func persistUnregisteringRemovesOnlyTheGivenID() async throws {
        let (sut, _) = try makeSUT()

        await sut.persist(isRegistered: true, id: Self.firstWalletID)
        await sut.persist(isRegistered: true, id: Self.secondWalletID)
        await sut.persist(isRegistered: false, id: Self.firstWalletID)

        #expect(await sut.retrieve(id: Self.firstWalletID) == false)
        #expect(await sut.retrieve(id: Self.secondWalletID) == true)
    }

    @Test
    func persistIsIdempotent() async throws {
        let (sut, userDefaults) = try makeSUT()

        await sut.persist(isRegistered: true, id: Self.firstWalletID)
        await sut.persist(isRegistered: true, id: Self.firstWalletID)

        let expectedStoredIDs = [Self.firstWalletID.hashedStringValue(message: Self.key)]

        #expect(userDefaults.stringArray(forKey: Self.key) == expectedStoredIDs)
    }
}

// MARK: - Factory methods

extension UserDefaultsUserWalletRegistrationStatusRepositoryTests {
    private static let key = "com.tangem.backendAuthentication.registeredUserWalletIDs"

    private static let firstWalletID = UserWalletId(value: Data([0x01, 0x02, 0x03]))
    private static let secondWalletID = UserWalletId(value: Data([0x04, 0x05, 0x06]))

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) throws -> (
        sut: UserDefaultsUserWalletRegistrationStatusRepository,
        userDefaults: UserDefaults
    ) {
        let userDefaults = try #require(UserDefaults(suiteName: suiteName), sourceLocation: sourceLocation)
        userDefaults.removePersistentDomain(forName: suiteName)
        trackForMemoryLeaks(userDefaults, sourceLocation: sourceLocation)

        let sut = UserDefaultsUserWalletRegistrationStatusRepository(userDefaults: userDefaults)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)

        return (sut, userDefaults)
    }
}
