//
//
//

import SwiftUI
import TangemAssets
import TangemUI

struct WCTransactionSecurityAlertState: Equatable {
    let title: String
    let subtitle: String
    let icon: Icon
    let primaryButton: ButtonSettings
    let secondaryButton: ButtonSettings

    struct Icon: Equatable {
        let asset: ImageType
        let color: Color
    }

    struct ButtonSettings: Equatable {
        let title: String
        let style: MainButton.Style
        let isLoading: Bool
    }
}

extension WCTransactionSecurityAlertState {
    init(from state: WCTransactionSecurityAlertState, isLoading: Bool) {
        title = state.title
        subtitle = state.subtitle
        icon = state.icon
        primaryButton = state.primaryButton
        secondaryButton = .init(
            title: state.secondaryButton.title,
            style: state.secondaryButton.style,
            isLoading: isLoading
        )
    }
}
