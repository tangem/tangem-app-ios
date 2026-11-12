//
//  AllServicesLayout.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AllServicesLayout {
    let sections: [Section]
}

// MARK: - Section

extension AllServicesLayout {
    struct Section {
        let id: AllServicesSectionID
        let items: [AllServicesItemID]
    }
}

// MARK: - Standard

extension AllServicesLayout {
    static let standard = AllServicesLayout(
        sections: [
            Section(id: .account, items: [.cryptoAccount, .jointAccount]),
        ]
    )
}
