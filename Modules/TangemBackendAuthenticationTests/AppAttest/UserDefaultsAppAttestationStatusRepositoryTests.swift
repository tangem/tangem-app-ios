//
//  UserDefaultsAppAttestationStatusRepositoryTests.swift
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
final class UserDefaultsAppAttestationStatusRepositoryTests: LeakTrackingTestSuite {
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
    func retrieveReflectsPersistedValue(isAppAttested: Bool) throws {
        let (sut, _) = try makeSUT()

        sut.persist(isAppAttested: isAppAttested)

        #expect(sut.retrieve() == isAppAttested)
    }

    @Test(arguments: [true, false])
    func persistWritesToTheUnderlyingUserDefaultsInstance(isAppAttested: Bool) throws {
        let (sut, userDefaults) = try makeSUT()

        sut.persist(isAppAttested: isAppAttested)

        #expect(userDefaults.bool(forKey: Self.key) == isAppAttested)
    }

    @Test(arguments: [true, false])
    func retrieveReadsFromTheUnderlyingUserDefaultsInstance(isAppAttested: Bool) throws {
        let (sut, userDefaults) = try makeSUT()

        userDefaults.set(isAppAttested, forKey: Self.key)

        #expect(sut.retrieve() == isAppAttested)
    }
}

// MARK: - Factory methods

extension UserDefaultsAppAttestationStatusRepositoryTests {
    private static let key = "com.tangem.backendAuthentication.isAppAttested"

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) throws -> (
        sut: UserDefaultsAppAttestationStatusRepository,
        userDefaults: UserDefaults
    ) {
        let userDefaults = try #require(UserDefaults(suiteName: suiteName), sourceLocation: sourceLocation)
        userDefaults.removePersistentDomain(forName: suiteName)
        trackForMemoryLeaks(userDefaults, sourceLocation: sourceLocation)

        return (UserDefaultsAppAttestationStatusRepository(userDefaults: userDefaults), userDefaults)
    }
}
