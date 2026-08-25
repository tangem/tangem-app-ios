//
//  SecurityKeychainRepositoryTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import Testing
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct SecurityKeychainRepositoryTests {
    @Test
    func insertPassesCorrectAttributesToSecItemAdd() async throws {
        let someKeychainService = "someService"
        let someKeychainAccount = "someAccount"
        let someData = Data.any

        let sut = Self.makeSUT(
            keychainService: someKeychainService,
            keychainAccount: someKeychainAccount,
            secItemAdd: { actualAttributes, _ in
                let expectedAttributes = Self.makeSecItemAddAttributes(
                    keychainService: someKeychainService,
                    keychainAccount: someKeychainAccount,
                    data: someData
                )

                #expect(
                    actualAttributes == expectedAttributes,
                    """
                    attributes passed to SecItemAdd do not match the expected values.
                    Data inserted into the Keychain may be corrupted.
                    """
                )
                return errSecSuccess
            }
        )

        try await sut.insert(someData)
    }

    @Test
    func insertSucceedsWhenSecItemAddReturnsSuccessStatusCode() async throws {
        let sut = Self.makeSUT(secItemAdd: { _, _ in errSecSuccess })

        try await sut.insert(Data.any)
    }

    @Test
    func insertThrowsInsertFailedWhenSecItemAddReturnsFailureStatusCode() async {
        let insertFailureStatusCode = errSecInteractionNotAllowed
        let sut = Self.makeSUT(secItemAdd: { _, _ in insertFailureStatusCode })

        await #expect(throws: KeychainRepositoryError.insertFailed(status: insertFailureStatusCode)) {
            try await sut.insert(Data.any)
        }
    }

    @Test
    func insertThrowsDuplicateItemWhenSecItemAddReturnsDuplicateItemStatusCode() async {
        let sut = Self.makeSUT(secItemAdd: { _, _ in errSecDuplicateItem })

        await #expect(throws: KeychainRepositoryError.duplicateItem) {
            try await sut.insert(Data.any)
        }
    }

    @Test
    func retrievePassesCorrectQueryToSecItemCopyMatching() async throws {
        let someKeychainService = "someService"
        let someKeychainAccount = "someAccount"

        let sut = Self.makeSUT(
            keychainService: someKeychainService,
            keychainAccount: someKeychainAccount,
            secItemCopyMatching: { actualQuery, result in
                let expectedQuery = Self.makeSecItemCopyMatchingQuery(
                    keychainService: someKeychainService,
                    keychainAccount: someKeychainAccount
                )

                result?.pointee = Data.any as CFTypeRef

                #expect(
                    actualQuery == expectedQuery,
                    """
                    query passed to SecItemCopyMatching does not match the expected value.
                    Data retrieved from the Keychain may be corrupted.
                    """
                )

                return errSecSuccess
            }
        )

        _ = try await sut.retrieve()
    }

    @Test
    func retrieveReturnsTheFoundDataWhenSecItemCopyMatchingSucceeds() async throws {
        let expectedData = Data.any

        let sut = Self.makeSUT(
            secItemCopyMatching: { _, result in
                result?.pointee = expectedData as CFTypeRef
                return errSecSuccess
            }
        )

        let retrievedData = try await sut.retrieve()

        #expect(retrievedData == expectedData)
    }

    @Test
    func retrieveReturnsNilWhenSecItemCopyMatchingReturnsNotFoundStatusCode() async throws {
        let sut = Self.makeSUT(secItemCopyMatching: { _, _ in errSecItemNotFound })

        let retrievedData = try await sut.retrieve()

        #expect(retrievedData == nil)
    }

    @Test
    func retrieveThrowsItemCorruptedWhenTheFoundItemIsNotData() async {
        let sut = Self.makeSUT(
            secItemCopyMatching: { _, result in
                result?.pointee = "not data" as CFTypeRef
                return errSecSuccess
            }
        )

        await #expect(throws: KeychainRepositoryError.itemCorrupted) {
            _ = try await sut.retrieve()
        }
    }

    @Test
    func retrieveThrowsRetrieveFailedWhenSecItemCopyMatchingReturnsFailureStatusCode() async {
        let retrieveFailureStatusCode = errSecInteractionNotAllowed
        let sut = Self.makeSUT(secItemCopyMatching: { _, _ in retrieveFailureStatusCode })

        await #expect(throws: KeychainRepositoryError.retrieveFailed(status: retrieveFailureStatusCode)) {
            _ = try await sut.retrieve()
        }
    }

    @Test
    func updatePassesCorrectQueryAndAttributesToSecItemUpdate() async throws {
        let someKeychainService = "someService"
        let someKeychainAccount = "someAccount"
        let someData = Data.any

        let sut = Self.makeSUT(
            keychainService: someKeychainService,
            keychainAccount: someKeychainAccount,
            secItemUpdate: { actualQuery, actualAttributesToUpdate in
                let expectedQuery = Self.makeSecItemUpdateQuery(
                    keychainService: someKeychainService,
                    keychainAccount: someKeychainAccount
                )
                let expectedAttributesToUpdate = Self.makeSecItemUpdateAttributesToUpdate(data: someData)

                #expect(
                    actualQuery == expectedQuery,
                    """
                    query passed to SecItemUpdate does not match the expected value.
                    Data updated in the Keychain may be corrupted.
                    """
                )
                #expect(
                    actualAttributesToUpdate == expectedAttributesToUpdate,
                    """
                    attributes to update passed to SecItemUpdate do not match the expected value.
                    Data updated in the Keychain may be corrupted.
                    """
                )

                return errSecSuccess
            }
        )

        try await sut.update(someData)
    }

    @Test
    func updateSucceedsWhenSecItemUpdateReturnsSuccessStatusCode() async throws {
        let sut = Self.makeSUT(secItemUpdate: { _, _ in errSecSuccess })

        try await sut.update(Data.any)
    }

    @Test
    func updateThrowsUpdateFailedWhenSecItemUpdateReturnsFailureStatusCode() async {
        let updateFailureStatusCode = errSecInteractionNotAllowed
        let sut = Self.makeSUT(secItemUpdate: { _, _ in updateFailureStatusCode })

        await #expect(throws: KeychainRepositoryError.updateFailed(status: updateFailureStatusCode)) {
            try await sut.update(Data.any)
        }
    }

    @Test
    func deletePassesCorrectQueryToSecItemDelete() async throws {
        let someKeychainService = "someService"
        let someKeychainAccount = "someAccount"

        let sut = Self.makeSUT(
            keychainService: someKeychainService,
            keychainAccount: someKeychainAccount,
            secItemDelete: { actualQuery in
                let expectedQuery = Self.makeSecItemDeleteQuery(
                    keychainService: someKeychainService,
                    keychainAccount: someKeychainAccount
                )

                #expect(
                    actualQuery == expectedQuery,
                    """
                    query passed to SecItemDelete does not match the expected value.
                    The wrong Keychain item may be deleted, or the intended item may not be removed at all.
                    """
                )

                return errSecSuccess
            }
        )

        try await sut.delete()
    }

    @Test
    func deleteSucceedsWhenSecItemDeleteReturnsSuccessStatusCode() async throws {
        let sut = Self.makeSUT(secItemDelete: { _ in errSecSuccess })

        try await sut.delete()
    }

    @Test
    func deleteSucceedsWhenSecItemDeleteReturnsNotFoundStatusCode() async throws {
        let sut = Self.makeSUT(secItemDelete: { _ in errSecItemNotFound })

        try await sut.delete()
    }

    @Test
    func deleteThrowsDeleteFailedWhenSecItemDeleteReturnsFailureStatusCode() async {
        let deleteFailureStatusCode = errSecInteractionNotAllowed
        let sut = Self.makeSUT(secItemDelete: { _ in deleteFailureStatusCode })

        await #expect(throws: KeychainRepositoryError.deleteFailed(status: deleteFailureStatusCode)) {
            try await sut.delete()
        }
    }

    @Test
    func updateOrInsertInsertsWhenNoItemExists() async throws {
        let sut = Self.makeSUT(
            secItemAdd: { _, _ in errSecSuccess },
            secItemUpdate: secItemUpdateDummy
        )

        try await sut.updateOrInsert(Data.any)
    }

    @Test
    func updateOrInsertFallsBackToUpdateWhenAnItemAlreadyExists() async throws {
        let sut = Self.makeSUT(
            secItemAdd: { _, _ in errSecDuplicateItem },
            secItemUpdate: { _, _ in errSecSuccess }
        )

        try await sut.updateOrInsert(Data.any)
    }

    @Test
    func updateOrInsertPropagatesInsertFailureWithoutCallingUpdate() async {
        let insertFailureStatusCode = errSecInteractionNotAllowed
        let sut = Self.makeSUT(
            secItemAdd: { _, _ in insertFailureStatusCode },
            secItemUpdate: secItemUpdateDummy
        )

        await #expect(throws: KeychainRepositoryError.insertFailed(status: insertFailureStatusCode)) {
            try await sut.updateOrInsert(Data.any)
        }
    }

    @Test
    func updateOrInsertPropagatesUpdateFailureWhenAnItemAlreadyExists() async {
        let updateFailureStatusCode = errSecInteractionNotAllowed
        let sut = Self.makeSUT(
            secItemAdd: { _, _ in errSecDuplicateItem },
            secItemUpdate: { _, _ in updateFailureStatusCode }
        )

        await #expect(throws: KeychainRepositoryError.updateFailed(status: updateFailureStatusCode)) {
            try await sut.updateOrInsert(Data.any)
        }
    }
}

// MARK: - Testing doubles and factory methods

private typealias SecItemAddFunction = @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
private typealias SecItemUpdateFunction = @Sendable (CFDictionary, CFDictionary) -> OSStatus
private typealias SecItemCopyMatchingFunction = @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
private typealias SecItemDeleteFunction = @Sendable (CFDictionary) -> OSStatus

private let secItemAddDummy: SecItemAddFunction = { _, _ in
    Issue.record("Unexpected SecItemAdd function call.")
    return OSStatus.dummy
}

private let secItemUpdateDummy: SecItemUpdateFunction = { _, _ in
    Issue.record("Unexpected SecItemUpdate function call.")
    return OSStatus.dummy
}

private let secItemCopyMatchingDummy: SecItemCopyMatchingFunction = { _, _ in
    Issue.record("Unexpected SecItemCopyMatching function call.")
    return OSStatus.dummy
}

private let secItemDeleteDummy: SecItemDeleteFunction = { _ in
    Issue.record("Unexpected SecItemDelete function call.")
    return OSStatus.dummy
}

extension SecurityKeychainRepositoryTests {
    private static func makeSUT(
        keychainService: String = "anyService",
        keychainAccount: String = "anyAccount",
        secItemAdd: @escaping SecItemAddFunction = secItemAddDummy,
        secItemUpdate: @escaping SecItemUpdateFunction = secItemUpdateDummy,
        secItemCopyMatching: @escaping SecItemCopyMatchingFunction = secItemCopyMatchingDummy,
        secItemDelete: @escaping SecItemDeleteFunction = secItemDeleteDummy
    ) -> SecurityKeychainRepository {
        SecurityKeychainRepository(
            keychainService: keychainService,
            keychainAccount: keychainAccount,
            keychainFunctions: SecurityKeychainRepository.KeychainFunctions(
                secItemAdd: secItemAdd,
                secItemUpdate: secItemUpdate,
                secItemCopyMatching: secItemCopyMatching,
                secItemDelete: secItemDelete
            )
        )
    }

    private static func makeSecItemAddAttributes(keychainService: String, keychainAccount: String, data: Data) -> CFDictionary {
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecUseDataProtectionKeychain: true,
        ]

        return attributes as CFDictionary
    }

    private static func makeSecItemCopyMatchingQuery(keychainService: String, keychainAccount: String) -> CFDictionary {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
            kSecUseDataProtectionKeychain: true,
        ]

        return query as CFDictionary
    }

    private static func makeSecItemUpdateQuery(keychainService: String, keychainAccount: String) -> CFDictionary {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain: true,
        ]

        return query as CFDictionary
    }

    private static func makeSecItemUpdateAttributesToUpdate(data: Data) -> CFDictionary {
        let attributesToUpdate: [CFString: Any] = [kSecValueData: data]
        return attributesToUpdate as CFDictionary
    }

    private static func makeSecItemDeleteQuery(keychainService: String, keychainAccount: String) -> CFDictionary {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecUseDataProtectionKeychain: true,
        ]

        return query as CFDictionary
    }
}

private extension OSStatus {
    static let dummy: OSStatus = -1
}

private extension Data {
    static let any = Data("any persisted data".utf8)
}
