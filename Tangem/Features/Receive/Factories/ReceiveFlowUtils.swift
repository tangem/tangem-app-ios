//
//  ReceiveFlowUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

struct ReceiveAddressInfoUtils {
    private let colorScheme: ColorScheme

    init(colorScheme: ColorScheme = .whiteBlack) {
        self.colorScheme = colorScheme
    }

    func makeAddressInfos(from addresses: [Address]) -> [ReceiveAddressInfo] {
        addresses.map { address in
            ReceiveAddressInfo(
                address: address.value,
                type: address.type,
                localizedName: address.localizedName,
                addressQRImage: QrCodeGenerator.generateQRCode(
                    from: address.value,
                    backgroundColor: colorScheme.backgroundColor,
                    foregroundColor: colorScheme.foregroundColor
                )
            )
        }
    }
}

extension ReceiveAddressInfoUtils {
    enum ColorScheme {
        case whiteBlack
        case clearBlack

        var backgroundColor: UIColor {
            switch self {
            case .whiteBlack:
                return .white
            case .clearBlack:
                return .clear
            }
        }

        var foregroundColor: UIColor {
            return .black
        }
    }
}
