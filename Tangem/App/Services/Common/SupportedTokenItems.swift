//
//  SupportedTokenItems.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class SupportedTokenItems { // [REDACTED_TODO_COMMENT]
    func loadCoins(requestModel: CoinsListRequestModel) -> AnyPublisher<[CoinModel], Error> {
        readTestnetList()
            .map { list in
                list.coins.compactMap {
                    CoinModel(with: $0, baseImageURL: list.imageHost)
                        .withFiltered(networkIds: requestModel.networkIds)
                }
            }
            .eraseToAnyPublisher()
    }

    private func readTestnetList() -> AnyPublisher<CoinsResponse, Error> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { testnet in
                try JsonUtils.readBundleFile(with: Constants.testFilename,
                                             type: CoinsResponse.self,
                                             shouldAddCompilationCondition: false)
            }
            .eraseToAnyPublisher()
    }
}

fileprivate extension SupportedTokenItems {
    enum Constants {
        static let testFilename: String = "testnet_tokens"
    }
}

private extension CoinModel {
    /// Filter the `tokenItems` for supportedCurves. Used only for testnet coinds from a local file
    func withFiltered(networkIds: String?) -> CoinModel? {
        let networks = networkIds?
            .split(separator: ",")
            .compactMap { String($0) }

        let filteredItems = items.filter { item in
            networks?.contains(item.blockchain.networkId) ?? true
        }

        if filteredItems.isEmpty {
            return nil
        }

        return makeCopy(with: filteredItems)
    }

    private func makeCopy(with items: [TokenItem]) -> CoinModel {
        CoinModel(id: id, name: name, symbol: symbol, imageURL: imageURL, items: items)
    }
}
