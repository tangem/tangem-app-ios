//
//  CommonAPIListProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class CommonAPIListProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private var locallyStoredList: APIList?
    private var loadedFromRemoteList: APIList?

    func initialize() {
        parseLocalFile()
        loadRemoteFile()
    }

    private func log<T>(_ message: @autoclosure () -> T, function: String = #function) {
        AppLog.shared.debug("[CommonAPIListProvider, line: \(function)] - \(message())")
    }

    private func parseLocalFile() {
        guard let url = Bundle.main.url(forResource: "providers_order", withExtension: "json") else {
            log("providers_order.json file not found")
            return
        }

        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let order = try decoder.decode(APIListDTO.self, from: jsonData)
            locallyStoredList = convertToSDKModels(order)
        } catch {
            log("Failed to parse providers_order file. Error: \(error)")
        }
    }

    private func loadRemoteFile() {
        let startTime = CFAbsoluteTimeGetCurrent()
        Task { [weak self] in
            guard let self else { return }
            do {
                let loadedList = try await tangemApiService.loadAPIList()
                loadedFromRemoteList = convertToSDKModels(loadedList)
            } catch {
                log("Failed to load API list from server. Error: \(error)")
            }
            let endTime = CFAbsoluteTimeGetCurrent()
            log("API list loading and parsing time: \(endTime - startTime) seconds")
        }
    }

    private func convertToSDKModels(_ listDTO: APIListDTO) -> APIList {
        var APIList: APIList = [:]
        listDTO.forEach { element in
            let apiList: [NetworkProviderType] = element.value.compactMap { apiInfo in
                switch APIType(rawValue: apiInfo.type) {
                case .public:
                    guard let link = apiInfo.url else {
                        return nil
                    }

                    return NetworkProviderType.public(link: link)
                case .private:
                    return mapToNetworkProviderType(name: apiInfo.name)
                case .none:
                    return nil
                }
            }

            APIList[element.key] = apiList
        }

        return APIList
    }

    private func mapToNetworkProviderType(name: String?) -> NetworkProviderType? {
        guard
            let name,
            let apiProvider = APIProvider(rawValue: name)
        else {
            return nil
        }

        return apiProvider.blockchainProvider
    }
}

extension CommonAPIListProvider: APIListProvider {
    var apiList: APIList {
        if let loadedFromRemoteList {
            return loadedFromRemoteList
        }

        if let locallyStoredList {
            return locallyStoredList
        }

        return [:]
    }
}
