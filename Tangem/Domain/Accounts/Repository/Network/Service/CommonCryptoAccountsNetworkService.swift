//
//  CommonCryptoAccountsNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import TangemFoundation

/// Conforms to both `CryptoAccountsNetworkService` and `ArchivedCryptoAccountsProvider` protocols.
final class CommonCryptoAccountsNetworkService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.cryptoAccountsETagStorage) private var eTagStorage: CryptoAccountsETagStorage

    private let userWalletId: UserWalletId
    private let mapper: CryptoAccountsNetworkMapper
    private let walletsNetworkService: WalletsNetworkService

    init(
        userWalletId: UserWalletId,
        mapper: CryptoAccountsNetworkMapper,
        walletsNetworkService: WalletsNetworkService
    ) {
        self.userWalletId = userWalletId
        self.mapper = mapper
        self.walletsNetworkService = walletsNetworkService
    }

    private func retry<T>(retryCount: Int, work: () async throws -> T) async throws(CryptoAccountsNetworkServiceError) -> T {
        var currentRetryAttempt = 0
        var lastError: CryptoAccountsNetworkServiceError?

        while currentRetryAttempt <= retryCount {
            do {
                // Send the request immediately on the first attempt, then apply exponential backoff for subsequent attempts
                if currentRetryAttempt > 0 {
                    let retryInterval = ExponentialBackoffInterval(retryAttempt: currentRetryAttempt)
                    try await Task.sleep(nanoseconds: retryInterval())
                }
                return try await work()
            } catch let error as CryptoAccountsNetworkServiceError where error.isCancellationError {
                throw error // Do not retry on cancellation error wrapped in `CryptoAccountsNetworkServiceError`
            } catch let error where error.isCancellationError {
                throw .underlyingError(error) // Do not retry on generic cancellation error
            } catch {
                lastError = (error as? CryptoAccountsNetworkServiceError) ?? .underlyingError(error)
                currentRetryAttempt += 1
            }
        }

        throw lastError ?? CryptoAccountsNetworkServiceError.noRetriesLeft
    }
}

// MARK: - WalletsNetworkService protocol conformance

extension CommonCryptoAccountsNetworkService: WalletsNetworkService {
    func createWallet(with context: some Encodable) async throws(CryptoAccountsNetworkServiceError) -> String? {
        let newRevision = try await walletsNetworkService.createWallet(with: context)

        if let newRevision {
            eTagStorage.saveETag(newRevision, for: userWalletId)
        }

        return newRevision
    }

    func updateWallet(context: some Encodable) async throws(CryptoAccountsNetworkServiceError) {
        try await walletsNetworkService.updateWallet(context: context)
    }
}

// MARK: - CryptoAccountsNetworkService protocol conformance

extension CommonCryptoAccountsNetworkService: CryptoAccountsNetworkService {
    func getCryptoAccounts(
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        return try await retry(retryCount: retryCount) {
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
                throw CryptoAccountsNetworkServiceError.underlyingError(error)
            }
        }
    }

    func saveAccounts(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        return try await retry(retryCount: retryCount) {
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
                throw CryptoAccountsNetworkServiceError.underlyingError(error)
            }
        }
    }

    func saveTokens(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) {
        return try await retry(retryCount: retryCount) {
            do {
                let (_, userTokensDTO) = mapper.map(request: cryptoAccounts)

                try await tangemApiService.saveTokens(list: userTokensDTO, for: userWalletId.stringValue)
            } catch let error as CryptoAccountsNetworkServiceError {
                throw error // Just re-throw an original error
            } catch let error as TangemAPIError where error.code == .notFound {
                throw CryptoAccountsNetworkServiceError.noAccountsCreated
            } catch {
                throw CryptoAccountsNetworkServiceError.underlyingError(error)
            }
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
