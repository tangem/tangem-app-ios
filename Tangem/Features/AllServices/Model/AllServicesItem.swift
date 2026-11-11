//
//  AllServicesItem.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets

struct AllServicesItem: Identifiable, Equatable {
    let id: AllServicesItemID
    let icon: Icon
    let title: String
    let subtitle: String
}

// MARK: - Icon

extension AllServicesItem {
    enum Icon: Equatable {
        case glyph(ImageType)
    }
}
