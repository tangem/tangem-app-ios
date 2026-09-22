//
//  CollectiblesAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import class Alamofire.Interceptor
import protocol Alamofire.RequestInterceptor
import Moya
import TangemBackendAuthentication
import TangemNetworkUtils

struct CollectiblesAPIService {
    typealias Provider = TangemProvider<CollectiblesAPITarget>

    private let provider: Provider
    private let baseURL: URL = .init(string: "https://collectibles.tests-d.com/")!
    private let decoder = JSONDecoder()

    init(
        provider: Provider = TangemProvider(
            configuration: .collectibles,
            additionalPlugins: [DeviceInfoPlugin()],
            requestInterceptor: Self.authenticationInterceptor
        )
    ) {
        self.provider = provider
    }
}

// MARK: - CollectiblesLoresProvider

extension CollectiblesAPIService: CollectiblesLoresProvider {
    func load() async throws -> CollectiblesLoreCatalogue {
        let response: CollectiblesDTO.MachineCategoriesResponse = try await request(.categories)
        return Mapper.mapToLoreCatalogue(response)
    }
}

// MARK: - CollectiblesPacksProvider

extension CollectiblesAPIService: CollectiblesPacksProvider {
    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let machinesRequest = CollectiblesDTO.MachinesRequest(
            categoryID: loreID,
            search: trimmedQuery.isEmpty ? nil : trimmedQuery,
            limit: Constants.pageLimit,
            cursor: cursor
        )

        let response: CollectiblesDTO.MachinesResponse = try await request(.machines(machinesRequest))

        return CollectiblesPacksPage(
            packs: response.machines.map(Mapper.mapToPack),
            hasNext: response.hasNext,
            cursor: response.cursor
        )
    }
}

// MARK: - CollectiblesMachineProvider

extension CollectiblesAPIService: CollectiblesMachineProvider {
    func load(id: String) async throws -> CollectiblesMachine {
        let machine: CollectiblesDTO.Machine = try await request(.machine(externalID: id))
        return Mapper.mapToMachine(machine)
    }
}

// MARK: - Pack opening

extension CollectiblesAPIService {
    // [REDACTED_TODO_COMMENT]
    func generatePackTransaction(_ request: CollectiblesDTO.GenerateTxRequest, userWalletID: String) async throws -> CollectiblesDTO.GenerateTxResponse {
        try await self.request(.generateTx(request, userWalletID: userWalletID))
    }

    func submitPackTransaction(_ request: CollectiblesDTO.SubmitTxRequest, userWalletID: String) async throws -> CollectiblesDTO.SubmitTxResponse {
        try await self.request(.submitTx(request, userWalletID: userWalletID))
    }
}

// MARK: - Networking

private extension CollectiblesAPIService {
    func request<T: Decodable>(_ target: CollectiblesAPITarget.Target) async throws -> T {
        let request = CollectiblesAPITarget(baseURL: baseURL, target: target)

        do {
            let response = try await provider.asyncRequest(request)
            let filtered = try response.filterSuccessfulStatusAndRedirectCodes()
            return try decoder.decode(T.self, from: filtered.data)
        } catch let error as CancellationError {
            throw error
        } catch let error as DecodingError {
            throw Error.decoding(error)
        } catch let error as MoyaError {
            throw Error(moyaError: error)
        } catch {
            throw Error.connection(underlying: error)
        }
    }
}

// MARK: - Authentication

private extension CollectiblesAPIService {
    static var authenticationInterceptor: (any RequestInterceptor)? {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return nil
        }

        return Interceptor(
            adapter: BackendAuthenticationAssembly.requestAdapter,
            retrier: BackendAuthenticationAssembly.requestRetrier
        )
    }
}

// MARK: - Constants

private extension CollectiblesAPIService {
    enum Constants {
        static let pageLimit = 50
    }
}
