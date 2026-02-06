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
import class Alamofire.RetryPolicy

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
            } catch let error as CryptoAccountsNetworkServiceError where error.isClientSideError {
                throw error // There is no point in retrying 4XX errors because the request will fail again with the same error
            } catch let error where error.isCancellationError {
                throw .underlyingError(error) // Do not retry on generic cancellation error
            } catch {
                let serviceError = error as? CryptoAccountsNetworkServiceError

                // Ugly nil coalescing to check all possible cases the URL error can be wrapped in other errors
                if let networkErrorCode = serviceError?.networkErrorCode ?? error.networkErrorCode {
                    if !RetryPolicy.defaultRetryableURLErrorCodes.contains(networkErrorCode) {
                        // There is no point in retrying non-retryable URL errors like "bad URL" or "can not find host"
                        throw CryptoAccountsNetworkServiceError.underlyingError(error)
                    }
                }

                lastError = serviceError ?? .underlyingError(error)
                currentRetryAttempt += 1
            }
        }

        throw lastError ?? CryptoAccountsNetworkServiceError.noRetriesLeft
    }
}

// MARK: - WalletsNetworkService protocol conformance

extension CommonCryptoAccountsNetworkService: WalletsNetworkService {
    func createWallet(with context: some Encodable) async throws(CryptoAccountsNetworkServiceError) {
        do {
            let newRevision = try await tangemApiService.createWallet(with: context)

            if let newRevision {
                eTagStorage.saveETag(newRevision, for: userWalletId)
            }
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch {
            throw .underlyingError(error)
        }
    }

    func updateWallet(userWalletId: String, context: some Encodable) async throws(CryptoAccountsNetworkServiceError) {
        do {
            try await tangemApiService.updateWallet(by: userWalletId, context: context)
        } catch let error as CryptoAccountsNetworkServiceError {
            throw error // Just re-throw an original error
        } catch {
            throw .underlyingError(error)
        }
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

// MARK: - Convenience extensions

private extension CryptoAccountsNetworkServiceError {
    var isClientSideError: Bool {
        switch self {
        case .underlyingError(let tangemAPIError as TangemAPIError):
            return (400 ... 499).contains(tangemAPIError.code.rawValue)
        default:
            return false
        }
    }

    var networkErrorCode: URLError.Code? {
        // Sometimes `AFError` is wrapped in the `MoyaError` as an underlying error.
        func networkErrorCodeFromAFError() -> URLError.Code? {
            underlyingError?.asMoyaError?.underlyingError?.asAFError?.networkErrorCode
        }

        return networkErrorCodeFromAFError() ?? underlyingError?.networkErrorCode
    }
}
