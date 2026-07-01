//
//  AddressBookContactSnapshot.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AddressBookContactSnapshot: Equatable {
    let name: String
    let color: AccountModel.CompositeIcon.Color
    let walletId: String
    let entries: Set<Entry>
}

extension AddressBookContactSnapshot {
    struct Entry: Hashable {
        let address: String
        let networkId: String
        let memo: String
    }
}
