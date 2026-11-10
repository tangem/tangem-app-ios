//
//  AllServicesLayout.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AllServicesLayout {
    let actions: [AllServicesItemID]
}

// MARK: - Standard

extension AllServicesLayout {
    static let standard = AllServicesLayout(actions: [.addWallet])
}
