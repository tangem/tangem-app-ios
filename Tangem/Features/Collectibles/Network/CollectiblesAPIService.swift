//
//  CollectiblesAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct CollectiblesAPIService {
    typealias Provider = TangemProvider<CollectiblesAPITarget>

    private let provider: Provider
    private let baseURL: URL = .init(string: "https://collectibles.tests-d.com/")!
    private let decoder = JSONDecoder()

    init(provider: Provider = TangemProvider(configuration: .collectibles, additionalPlugins: [DeviceInfoPlugin()])) {
        self.provider = provider
    }
}

// MARK: - CollectiblesLoresProvider

extension CollectiblesAPIService: CollectiblesLoresProvider {
    func load() async throws -> CollectiblesLoreCatalogue {
        let response: CollectiblesDTO.MachineCategoriesResponse = try await request(.categories)

        let lores = response.categories.map { category in
            CollectiblesLore(id: category.id, title: category.name, packsCount: category.machinesQuantity)
        }

        return CollectiblesLoreCatalogue(lores: lores, totalPacksCount: response.totalMachinesQuantity)
    }
}

// MARK: - CollectiblesPacksProvider

extension CollectiblesAPIService: CollectiblesPacksProvider {
    func load(loreID: String?, query: String, cursor: String?) async throws -> CollectiblesPacksPage {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let machinesRequest = CollectiblesMachinesRequest(
            categoryID: loreID,
            search: trimmedQuery.isEmpty ? nil : trimmedQuery,
            limit: Constants.pageLimit,
            cursor: cursor
        )

        let response: CollectiblesDTO.MachinesResponse = try await request(.machines(machinesRequest))

        return CollectiblesPacksPage(
            packs: response.machines.map(mapToPack),
            hasNext: response.hasNext,
            cursor: response.cursor
        )
    }
}

// MARK: - Mapping

private extension CollectiblesAPIService {
    func mapToPack(_ machine: CollectiblesDTO.Machine) -> CollectiblesPack {
        CollectiblesPack(
            id: machine.externalId,
            name: machine.shortName.isEmpty ? machine.name : machine.shortName,
            loreID: machine.categoryId,
            price: machine.price / Constants.dollarScale,
            currencyCode: AppConstants.usdCurrencyCode,
            buybackRate: Decimal(machine.instantBuybackPercent) / Constants.percentScale,
            artworkURL: machine.image.flatMap(URL.init)
        )
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

// MARK: - Constants

private extension CollectiblesAPIService {
    enum Constants {
        static let pageLimit = 50

        /// Backend money convention: dollar amounts arrive multiplied by 100 (`price: 5000` is $50).
        static let dollarScale = Decimal(100)
        /// `instantBuybackPercent` is whole percent (85), the domain rate is a fraction (0.85).
        static let percentScale = Decimal(100)
    }
}
