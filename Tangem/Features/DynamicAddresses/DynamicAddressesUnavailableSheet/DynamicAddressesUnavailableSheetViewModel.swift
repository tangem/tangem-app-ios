//
//  DynamicAddressesUnavailableSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

protocol DynamicAddressesUnavailableSheetRoutable: AnyObject {
    func closeDynamicAddressesUnavailableSheet()
}

final class DynamicAddressesUnavailableSheetViewModel: FloatingSheetContentViewModel {
    let messageType: MessageType

    var icon: BottomSheetErrorContentView.Icon { messageType.icon }
    var title: String { messageType.title }
    var subtitle: String { messageType.subtitle }
    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(title: Localization.commonGotIt, action: close)
    }

    private weak var coordinator: (any DynamicAddressesUnavailableSheetRoutable)?

    init(messageType: MessageType, coordinator: any DynamicAddressesUnavailableSheetRoutable) {
        self.messageType = messageType
        self.coordinator = coordinator
    }

    func close() {
        coordinator?.closeDynamicAddressesUnavailableSheet()
    }
}

// MARK: - MessageType

extension DynamicAddressesUnavailableSheetViewModel {
    enum MessageType {
        case unavailable
        case hasCustomToken

        var icon: BottomSheetErrorContentView.Icon {
            switch self {
            case .unavailable: return .attention
            case .hasCustomToken: return .attention
            }
        }

        var title: String {
            switch self {
            case .unavailable: return Localization.dynamicAddressesErrorServiceUnavailableTitle
            case .hasCustomToken: return Localization.dynamicAddressesErrorHasCustomTokenTitle
            }
        }

        var subtitle: String {
            switch self {
            case .unavailable:
                return Localization.dynamicAddressesErrorServiceUnavailableDescription
            case .hasCustomToken:
                return Localization.dynamicAddressesErrorHasCustomTokenDescription
            }
        }
    }
}
