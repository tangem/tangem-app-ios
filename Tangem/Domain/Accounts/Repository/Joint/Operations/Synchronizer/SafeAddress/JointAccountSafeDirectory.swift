//
//  JointAccountSafeDirectory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JointAccountSafeDirectory {
    private let accountSafes: [JointAccountSafe]

    var safeAddresses: Set<String> {
        accountSafes.map(\.safeAddress).toSet()
    }

    init(_ accountSafes: [JointAccountSafe]) {
        self.accountSafes = accountSafes
    }

    func safeAddress(forCryptoAccountId cryptoAccountId: String) -> String? {
        accountSafes.first { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }?.safeAddress
    }

    func cryptoAccountId(forSafeAddress safeAddress: String) -> String? {
        let safeAddress = safeAddress.lowercased()
        return accountSafes.first { $0.safeAddress == safeAddress }?.cryptoAccountId
    }

    func trustedItems(_ items: [JointOperationHistoryItem]) -> [JointOperationHistoryItem] {
        items.filter { cryptoAccountId(forSafeAddress: $0.safeAddress) != nil }
    }

    func records(from items: [JointOperationHistoryItem]) -> [JointAccountOperations] {
        items.reduce(into: []) { records, item in
            guard let cryptoAccountId = cryptoAccountId(forSafeAddress: item.safeAddress) else {
                return
            }

            guard let index = records.firstIndex(by: cryptoAccountId) else {
                records.append(JointAccountOperations(cryptoAccountId: cryptoAccountId, operations: [item.operation]))
                return
            }

            let record = records[index]
            records[index] = JointAccountOperations(
                cryptoAccountId: record.cryptoAccountId,
                operations: record.operations + [item.operation]
            )
        }
    }
}
