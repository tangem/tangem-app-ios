//
//  TangemPayUnavailableRegionStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPay

struct TangemPayUnavailableRegion: Codable, Hashable {
    let country: String
    let region: String?
}

protocol TangemPayUnavailableRegionStorage {
    func unavailableRegion(for product: TangemPayProduct) -> TangemPayUnavailableRegion?
    func unavailableRegionPublisher(for product: TangemPayProduct) -> AnyPublisher<TangemPayUnavailableRegion?, Never>
    func setUnavailableRegion(_ region: TangemPayUnavailableRegion, for product: TangemPayProduct)
    func clearUnavailableRegion(for product: TangemPayProduct)
}

extension AppSettings: TangemPayUnavailableRegionStorage {
    func unavailableRegion(for product: TangemPayProduct) -> TangemPayUnavailableRegion? {
        Self.decodeUnavailableRegion(tangemPayUnavailableRegion[product.rawValue])
    }

    func unavailableRegionPublisher(for product: TangemPayProduct) -> AnyPublisher<TangemPayUnavailableRegion?, Never> {
        $tangemPayUnavailableRegion
            .map { Self.decodeUnavailableRegion($0[product.rawValue]) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func setUnavailableRegion(_ region: TangemPayUnavailableRegion, for product: TangemPayProduct) {
        guard let data = try? JSONEncoder().encode(region),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        tangemPayUnavailableRegion[product.rawValue] = jsonString
    }

    func clearUnavailableRegion(for product: TangemPayProduct) {
        tangemPayUnavailableRegion[product.rawValue] = nil
    }

    private static func decodeUnavailableRegion(_ jsonString: String?) -> TangemPayUnavailableRegion? {
        guard let data = jsonString?.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(TangemPayUnavailableRegion.self, from: data)
    }
}
