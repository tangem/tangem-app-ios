//
//  CompositeIconColorPalette.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

enum CompositeIconColorPalette {
    static func color(for color: CompositeIconColor) -> Color {
        switch color {
        case .azure:
            return Colors.Accounts.azureBlue
        case .caribbeanBlue:
            return Colors.Accounts.caribbeanBlue
        case .dullLavender:
            return Colors.Accounts.dullLavender
        case .candyGrapeFizz:
            return Colors.Accounts.candyGrapeFizz
        case .sweetDesire:
            return Colors.Accounts.sweetDesire
        case .palatinateBlue:
            return Colors.Accounts.palatinateBlue
        case .fuchsiaNebula:
            return Colors.Accounts.fuchsiaNebula
        case .mexicanPink:
            return Colors.Accounts.mexicanPink
        case .pelati:
            return Colors.Accounts.pelati
        case .pattypan:
            return Colors.Accounts.pattypan
        case .ufoGreen:
            return Colors.Accounts.ufoGreen
        case .vitalGreen:
            return Colors.Accounts.vitalGreen
        }
    }
}
