//
//  CommonCryptoAccountsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Conforms to both `CryptoAccountsNetworkService` and `ArchivedCryptoAccountsProvider` protocols.
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
            let (newRevision, accountsDTO) = try await tangemApiService.getUserAccounts(userWalletId: userWalletId.stringValue)

            if let newRevision {
                eTagStorage.saveETag(newRevision, for: userWalletId)
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

    func saveAccounts(from cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        do {
            let (accountsDTO, _) = mapper.map(request: cryptoAccounts)

            guard let revision = eTagStorage.loadETag(for: userWalletId) else {
                throw CryptoAccountsNetworkServiceError.missingRevision
            }

            let (newRevision, newAccountsDTO) = try await tangemApiService.saveUserAccounts(
                userWalletId: userWalletId.stringValue,
                revision: revision,
                accounts: accountsDTO
            )

            if let newRevision {
                eTagStorage.saveETag(newRevision, for: userWalletId)
            }

            return mapper.map(response: newAccountsDTO)
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

    func saveTokens(from cryptoAccounts: [StoredCryptoAccount]) async throws(CryptoAccountsNetworkServiceError) {
        do {
            let (_, userTokensDTO) = mapper.map(request: cryptoAccounts)

            try await tangemApiService.saveTokens(list: userTokensDTO, for: userWalletId.stringValue)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch let error as TangemAPIError where error.code == .notFound {
            throw CryptoAccountsNetworkServiceError.noAccountsCreated
        } catch {
            throw .underlyingError(error)
        }
    }
}

// MARK: - ArchivedCryptoAccountsProvider protocol conformance

extension CommonCryptoAccountsNetworkService: ArchivedCryptoAccountsProvider {
    func getArchivedCryptoAccounts() async throws -> [ArchivedCryptoAccountInfo] {
        do {
            let archivedAccountsDTO = try await tangemApiService.getArchivedUserAccounts(userWalletId: userWalletId.stringValue)

            return mapper.map(response: archivedAccountsDTO)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch {
            throw CryptoAccountsNetworkServiceError.underlyingError(error)
        }
    }
}
