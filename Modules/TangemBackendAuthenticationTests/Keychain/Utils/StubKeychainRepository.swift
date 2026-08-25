//
//  StubKeychainRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import TangemBackendAuthentication

struct StubKeychainRepository: KeychainRepository {
    var insertResult: Result<Void, KeychainRepositoryError> = .success(())
    var updateResult: Result<Void, KeychainRepositoryError> = .success(())
    var retrieveResult: Result<Data?, KeychainRepositoryError> = .success(nil)
    var deleteResult: Result<Void, KeychainRepositoryError> = .success(())

    func insert(_ data: Data) throws(KeychainRepositoryError) {
        try insertResult.get()
    }

    func update(_ data: Data) throws(KeychainRepositoryError) {
        try updateResult.get()
    }

    func retrieve() throws(KeychainRepositoryError) -> Data? {
        try retrieveResult.get()
    }

    func delete() throws(KeychainRepositoryError) {
        try deleteResult.get()
    }
}
