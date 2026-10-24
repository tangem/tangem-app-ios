//
//  TangemPayResidencyStatusStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

struct TangemPayUnavailableRegion: Codable, Hashable {
    let country: String
    let region: String?
}

enum TangemPayResidencyStatus: Codable, Hashable {
    case pending
    case unavailable(TangemPayUnavailableRegion)
}

protocol TangemPayResidencyStatusStorage {
    func residencyStatus(userWalletId: UserWalletId, product: TangemPayProduct) -> TangemPayResidencyStatus?
    func setResidencyStatus(_ status: TangemPayResidencyStatus, userWalletId: UserWalletId, product: TangemPayProduct)
    func clearResidencyStatus(userWalletId: UserWalletId, product: TangemPayProduct)
    func deleteResidencyStatuses(userWalletId: UserWalletId)
}

extension AppSettings: TangemPayResidencyStatusStorage {
    func residencyStatus(userWalletId: UserWalletId, product: TangemPayProduct) -> TangemPayResidencyStatus? {
        residencyStatuses(userWalletId: userWalletId)[product.rawValue]
    }

    func setResidencyStatus(_ status: TangemPayResidencyStatus, userWalletId: UserWalletId, product: TangemPayProduct) {
        var statuses = residencyStatuses(userWalletId: userWalletId)
        statuses[product.rawValue] = status
        saveResidencyStatuses(statuses, userWalletId: userWalletId)
    }

    func clearResidencyStatus(userWalletId: UserWalletId, product: TangemPayProduct) {
        var statuses = residencyStatuses(userWalletId: userWalletId)
        statuses[product.rawValue] = nil
        saveResidencyStatuses(statuses, userWalletId: userWalletId)
    }

    func deleteResidencyStatuses(userWalletId: UserWalletId) {
        tangemPayResidencyStatus[residencyStatusKey(for: userWalletId)] = nil
    }
}

// MARK: - Private implementation

private extension AppSettings {
    func residencyStatusKey(for userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: StorageType.tangemPayResidencyStatus.rawValue)
    }

    func residencyStatuses(userWalletId: UserWalletId) -> [String: TangemPayResidencyStatus] {
        guard let data = tangemPayResidencyStatus[residencyStatusKey(for: userWalletId)]?.data(using: .utf8) else {
            return [:]
        }

        return (try? JSONDecoder().decode([String: TangemPayResidencyStatus].self, from: data)) ?? [:]
    }

    func saveResidencyStatuses(_ statuses: [String: TangemPayResidencyStatus], userWalletId: UserWalletId) {
        guard statuses.isNotEmpty else {
            deleteResidencyStatuses(userWalletId: userWalletId)
            return
        }

        guard let data = try? JSONEncoder().encode(statuses),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        tangemPayResidencyStatus[residencyStatusKey(for: userWalletId)] = jsonString
    }
}
