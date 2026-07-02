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

    init(api: TangemApiService = InjectedValues[\.tangemApiService]) {
        self.api = api
    }
}

extension CommonAddressBookNetworkService: AddressBookNetworkService {
    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult {
        do {
            let request = AddressBookDTO.SyncRequest(
                wallets: [.init(walletId: walletId.stringValue, etag: knownETag)]
            )
            let response = try await api.syncAddressBooks(request)

            guard let item = response.items.first else {
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
