//
//  APIListUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct APIListUtils {
    private let fileName = "providers_order"
    private let urlValidator = APIURLValidator()

    func parseLocalAPIListJson() throws -> APIList {
        let apiListDTO = try JsonUtils.readBundleFile(with: fileName, type: APIListDTO.self)
        return convertToSDKModels(apiListDTO)
    }

    func convertToSDKModels(_ listDTO: APIListDTO) -> APIList {
        return listDTO.reduce(into: [:]) { partialResult, element in
            let providers: [NetworkProviderType] = element.value.compactMap { apiInfo in
                switch APIType(rawValue: apiInfo.type) {
                case .public:
                    guard var link = apiInfo.url else {
                        return nil
                    }

                    link = link.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Check that link is valid
                    guard urlValidator.isLinkValid(link) else {
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
}
