//
//  CommonAddressBookNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

final class CommonAddressBookNetworkService {
    private let api: TangemApiService
    private let mapper = AddressBookNetworkMapper()

    private let pendingWallets = OSAllocatedUnfairLock(initialState: [AddressBookDTO.SyncRequest.Wallet]())

    private lazy var loadDebouncer = Debouncer<Result<AddressBookDTO.Response, Error>>(interval: Constants.debounceInterval) { [weak self] completion in
        self?.performPendingSync(completion: completion)
    }

    init(api: TangemApiService = InjectedValues[\.tangemApiService]) {
        self.api = api
        _ = loadDebouncer // Eager initialization of this lazy property to ensure that there are no race conditions
    }
}

extension CommonAddressBookNetworkService: AddressBookNetworkService {
    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult {
        do {
            pendingWallets.withLock { $0.append(.init(walletId: walletId.stringValue, etag: knownETag)) }

            let response = try await withCheckedThrowingContinuation { continuation in
                loadDebouncer.debounce { continuation.resume(with: $0) }
            }

            guard let item = response.items.keyedFirst(by: \.walletId)[walletId.stringValue] else {
                return knownETag == nil ? .notFound : .notModified
            }

            return try .fetched(mapper.mapToEnvelope(item))
        } catch let error as AddressBookNetworkMapper.MappingError {
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch MoyaError.objectMapping(let error, _) {
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch let error as DecodingError {
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch {
            throw AddressBookNetworkServiceError.underlyingError(error)
        }
    }

    func saveAddressBook(_ envelope: AddressBookEnvelope, walletId: UserWalletId, knownETag: String?) async throws -> AddressBookSaveResult {
        do {
            let response = try await api.updateAddressBook(
                walletId: walletId.stringValue,
                knownETag: knownETag,
                body: mapper.mapToUpdateRequest(envelope)
            )

            return try mapper.mapToSaveResult(response)
        } catch let error as TangemAPIError where error.code == .optimisticLockingFailed {
            throw AddressBookNetworkServiceError.inconsistentState
        } catch let error as AddressBookNetworkMapper.MappingError {
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch MoyaError.objectMapping(let error, _) {
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch let error as DecodingError {
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch {
            throw AddressBookNetworkServiceError.underlyingError(error)
        }
    }
}

// MARK: - Batched loading

private extension CommonAddressBookNetworkService {
    func performPendingSync(completion: @escaping (Result<AddressBookDTO.Response, Error>) -> Void) {
        let wallets = pendingWallets.withLock { pending in
            let wallets = pending
            pending.removeAll()
            return wallets
        }

        guard wallets.isNotEmpty else {
            completion(.failure(CancellationError()))
            return
        }

        runTask(in: self) { service in
            do {
                let chunks = wallets.chunked(into: Constants.syncChunkSize)
                ABLogger.info("Syncing \(wallets.count) wallet(s) in \(chunks.count) chunk(s)")

                let responses = try await TaskGroup<AddressBookDTO.Response>.tryExecuteKeepingOrder(items: chunks) { chunk in
                    try await service.api.syncAddressBooks(AddressBookDTO.SyncRequest(wallets: chunk))
                }

                completion(.success(AddressBookDTO.Response(items: responses.flatMap(\.items))))
            } catch {
                if !error.isCancellationError {
                    ABLogger.error("Sync failed (\(wallets.count) wallet(s))", error: error)
                }

                completion(.failure(error))
            }
        }
    }
}

// MARK: - Constants

private extension CommonAddressBookNetworkService {
    enum Constants {
        static let debounceInterval = 0.3
        static let syncChunkSize = 20
    }
}

// MARK: - Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
