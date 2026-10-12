//
//  UserDefaultsDeviceRegistrationStatusRepositoryTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
final class UserDefaultsDeviceRegistrationStatusRepositoryTests: LeakTrackingTestSuite {
    private let suiteName = "com.tangem.backendAuthentication.tests.\(UUID().uuidString)"

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    @Test
    func retrieveReturnsFalseByDefault() throws {
        let (sut, _) = try makeSUT()

        #expect(sut.retrieve() == false)
    }

    @Test(arguments: [true, false])
    func retrieveReflectsPersistedValue(isRegistered: Bool) throws {
        let (sut, _) = try makeSUT()

        sut.persist(isRegistered: isRegistered)

        #expect(sut.retrieve() == isRegistered)
    }

    @Test(arguments: [true, false])
    func persistWritesToTheUnderlyingUserDefaultsInstance(isRegistered: Bool) throws {
        let (sut, userDefaults) = try makeSUT()

        sut.persist(isRegistered: isRegistered)

        #expect(userDefaults.bool(forKey: Self.key) == isRegistered)
    }

    @Test(arguments: [true, false])
    func retrieveReadsFromTheUnderlyingUserDefaultsInstance(isRegistered: Bool) throws {
        let (sut, userDefaults) = try makeSUT()

        userDefaults.set(isRegistered, forKey: Self.key)

        #expect(sut.retrieve() == isRegistered)
    }
}

// MARK: - Factory methods

extension UserDefaultsDeviceRegistrationStatusRepositoryTests {
    private static let key = "com.tangem.backendAuthentication.isDeviceRegistered"

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) throws -> (
        sut: UserDefaultsDeviceRegistrationStatusRepository,
        userDefaults: UserDefaults
    ) {
        let userDefaults = try #require(UserDefaults(suiteName: suiteName), sourceLocation: sourceLocation)
        userDefaults.removePersistentDomain(forName: suiteName)
        trackForMemoryLeaks(userDefaults, sourceLocation: sourceLocation)

        return (UserDefaultsDeviceRegistrationStatusRepository(userDefaults: userDefaults), userDefaults)
    }
}
