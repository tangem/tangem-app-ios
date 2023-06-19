//
//  Analytics+DestinationAddressSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum DestinationAddressSource {
        case qrCode
        case pasteButton
        case pasteMenu

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .pasteButton:
                return .destinationAddressPasteButton
            case .pasteMenu:
                return .destinationAddressPastePopup
            case .qrCode:
                return .destinationAddressSourceQrCode
            }
        }
    }
}
