//
//  CommonAPIListProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonAPIListProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let remoteListRequestTimeout: TimeInterval = 5.0

    private var apiListSubject = CurrentValueSubject<APIList?, Never>(nil)

    func initialize() {
        runTask(withTimeout: remoteListRequestTimeout) { [weak self] in
            self?.log("onTimeout while file load")
            await self?.loadRemoteList()
        } onTimeout: { [weak self] in
            self?.loadLocalFile()
        }
    }

    private func loadRemoteList() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            log("Attempting to load API list from server")

            let loadedList = try await tangemApiService.loadAPIList()

            try Task.checkCancellation()

            var convertedRemoteAPIList = convertToSDKModels(loadedList)
            let localAPIListFile: APIList = try parseLocalFile()

            // Adding missing network providers to prevent case when no providers available for blockchain
            convertedRemoteAPIList.merge(localAPIListFile, uniquingKeysWith: { remote, local in
                return remote.isEmpty ? local : remote
            })

            apiListSubject.value = convertedRemoteAPIList
            let remoteFileParseTime = CFAbsoluteTimeGetCurrent()
            log("Remote API list loading and parsing time: \(remoteFileParseTime - startTime) seconds")
        } catch {
            if error is CancellationError || Task.isCancelled {
                log("Loading API list from server was cancelled. No action required")
                return
            }

            log("Failed to load API list from server. Error: \(error).\nAttempting to read local API list.")
            loadLocalFile()
        }
    }

    private func loadLocalFile() {
        do {
            let localAPIList = try parseLocalFile()
            apiListSubject.value = localAPIList
        } catch {
            log("Failed to parse local file.\nReason: \(error).\nPublishing empty list")
            apiListSubject.value = [:]
        }
    }

    private func parseLocalFile() throws -> APIList {
        guard let url = Bundle.main.url(forResource: "providers_order", withExtension: "json") else {
            log("Local file with API List  not found")
            throw APIListProviderError.localFileNotFound
        }

        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let order = try decoder.decode(APIListDTO.self, from: jsonData)

        return convertToSDKModels(order)
    }

    private func convertToSDKModels(_ listDTO: APIListDTO) -> APIList {
        return listDTO.reduce(into: [:]) { partialResult, element in
            let providers: [NetworkProviderType] = element.value.compactMap { apiInfo in
                switch APIType(rawValue: apiInfo.type) {
                case .public:
                    guard
                        let link = apiInfo.url,
                        // Check that link is valid
                        let _ = URL(string: link)
                    else {
                        return nil
                    }

                    return NetworkProviderType.public(link: link)
                case .private:
                    return mapToNetworkProviderType(name: apiInfo.name)
                case .none:
                    return nil
                }
            }

            partialResult[element.key] = providers
        }
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

    private func log<T>(_ message: @autoclosure () -> T, function: String = #function) {
        AppLog.shared.debug("[CommonAPIListProvider, line: \(function)] - \(message())")
    }
}

extension CommonAPIListProvider: APIListProvider {
    var apiList: APIList {
        return apiListSubject.value ?? [:]
    }

    var apiListPublisher: AnyPublisher<APIList, Never> {
        apiListSubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension CommonAPIListProvider {
    enum APIListProviderError: Error {
        case localFileNotFound
    }
}

#if DEBUG
extension CommonAPIListProvider {
    func parseLocalFileForTest() throws -> APIList {
        try parseLocalFile()
    }
}
#endif
