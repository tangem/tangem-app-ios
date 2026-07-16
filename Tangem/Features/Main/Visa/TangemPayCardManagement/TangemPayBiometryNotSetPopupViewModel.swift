//
//  TangemPayBiometryNotSetPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import LocalAuthentication
import TangemSdk
import TangemUI
import TangemAssets
import TangemLocalization

@MainActor
final class TangemPayBiometryNotSetPopupViewModel: TangemPayPopupViewModel {
    var icon: Image {
        content.icon
    }

    var title: AttributedString {
        AttributedString(content.title)
    }

    var description: AttributedString {
        AttributedString(content.description)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: content.buttonTitle,
            style: .primary,
            size: .default,
            action: onSetBiometry
        )
    }

    private let biometryType: LABiometryType
    private let onSetBiometry: () -> Void
    private let onClose: () -> Void

    private var content: Content {
        switch biometryType {
        case .faceID, .opticID:
            Content(
                icon: Assets.Biometry.faceId.image,
                title: Localization.tangempayFaceIdNotSetTitle,
                description: Localization.tangempayFaceIdNotSetDescription,
                buttonTitle: Localization.tangempayFaceIdNotSetButton
            )
        default:
            Content(
                icon: Assets.Biometry.touchId.image,
                title: Localization.tangempayTouchIdNotSetTitle,
                description: Localization.tangempayTouchIdNotSetDescription,
                buttonTitle: Localization.tangempayTouchIdNotSetButton
            )
        }
    }

    init(
        biometryType: LABiometryType = BiometricsUtil.biometryType,
        onSetBiometry: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.biometryType = biometryType
        self.onSetBiometry = onSetBiometry
        self.onClose = onClose
    }

    func dismiss() {
        onClose()
    }

    private struct Content {
        let icon: Image
        let title: String
        let description: String
        let buttonTitle: String
    }
}
