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
    @Injected(\.cryptoAccountsETagStorage) private var eTagStorage: CryptoAccountsETagStorage

    private let userWalletId: UserWalletId
    private let mapper: CryptoAccountsNetworkMapper

    init(
        userWalletId: UserWalletId,
        mapper: CryptoAccountsNetworkMapper
    ) {
        self.userWalletId = userWalletId
        self.mapper = mapper
    }
}

// MARK: - CryptoAccountsNetworkService protocol conformance

extension CommonCryptoAccountsNetworkService: CryptoAccountsNetworkService {
    func getCryptoAccounts() async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        do {
            let (revision, accountsDTO) = try await tangemApiService.getUserAccounts(userWalletId: userWalletId.stringValue)

            if let revision {
                eTagStorage.saveETag(revision, for: userWalletId)
            }

            return mapper.map(response: accountsDTO)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch let error as TangemAPIError where error.code == .notFound {
            throw CryptoAccountsNetworkServiceError.noAccountsCreated
        } catch {
            throw .underlyingError(error)
        }
    }

    func getArchivedCryptoAccounts() async throws(CryptoAccountsNetworkServiceError) -> [ArchivedCryptoAccountInfo] {
        do {
            let (revision, archivedAccountsDTO) = try await tangemApiService.getArchivedUserAccounts(userWalletId: userWalletId.stringValue)

            if let revision {
                eTagStorage.saveETag(revision, for: userWalletId)
            }

            return mapper.map(response: archivedAccountsDTO)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch {
            throw CryptoAccountsNetworkServiceError.underlyingError(error)
        }
    }

    func save(cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError) {
        do {
            guard let revision = eTagStorage.loadETag(for: userWalletId) else {
                throw CryptoAccountsNetworkServiceError.missingRevision
            }

            let accountsDTO = mapper.map(request: cryptoAccounts)
            let newRevision = try await tangemApiService.saveUserAccounts(
                userWalletId: userWalletId.stringValue,
                revision: revision,
                accounts: accountsDTO
            )

            if let newRevision {
                eTagStorage.saveETag(newRevision, for: userWalletId)
            }
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
