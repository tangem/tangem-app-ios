//
//  CommonCryptoAccountsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonCryptoAccountsNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: UserWalletId
    private let eTagStorage: CryptoAccountsETagStorage
    private let mapper: CryptoAccountsNetworkMapper

    init(
        userWalletId: UserWalletId,
        eTagStorage: CryptoAccountsETagStorage,
        mapper: CryptoAccountsNetworkMapper
    ) {
        self.userWalletId = userWalletId
        self.eTagStorage = eTagStorage
        self.mapper = mapper
    }
}

// MARK: - CryptoAccountsNetworkService protocol conformance

extension CommonCryptoAccountsNetworkService: CryptoAccountsNetworkService {
    func getCryptoAccounts() async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccounts {
        do {
            let (revision, accountsDTO) = try await tangemApiService.getUserAccounts(userWalletId: userWalletId.stringValue)

            guard let revision else {
                throw CryptoAccountsNetworkServiceError.missingRevision
            }

            eTagStorage.saveETag(revision, for: userWalletId)

            return mapper.map(response: accountsDTO)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch let error as TangemAPIError where error.code == .notFound {
            throw CryptoAccountsNetworkServiceError.noAccountsCreated
        } catch {
            throw .underlyingError(error)
        }
    }

    func getArchivedCryptoAccounts() async throws(CryptoAccountsNetworkServiceError) -> [StoredCryptoAccount] {
        // [REDACTED_TODO_COMMENT]
        throw CryptoAccountsNetworkServiceError.underlyingError("Not implemented")
    }

    func save(cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError) {
        do {
            guard let revision = eTagStorage.loadETag(for: userWalletId) else {
                throw CryptoAccountsNetworkServiceError.missingRevision
            }

            let accountsDTO = mapper.map(request: cryptoAccounts)

            try await tangemApiService.saveUserAccounts(
                userWalletId: userWalletId.stringValue,
                revision: revision,
                accounts: accountsDTO
            )
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch let error as TangemAPIError where error.code == .notFound {
            throw CryptoAccountsNetworkServiceError.noAccountsCreated
        } catch let error as TangemAPIError where error.code == .optimisticLockingFailed {
            throw CryptoAccountsNetworkServiceError.inconsistentState
        } catch {
            throw .underlyingError(error)
        }
    }
}
