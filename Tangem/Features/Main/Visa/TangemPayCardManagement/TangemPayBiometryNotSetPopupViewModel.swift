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

protocol TangemPayBiometryNotSetPopupRoutable: AnyObject {
    func openBiometrySettings()
    func closeBiometryNotSetPopup()
}

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
            action: setBiometry
        )
    }

    private let biometryType: LABiometryType
    private weak var coordinator: TangemPayBiometryNotSetPopupRoutable?

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
        coordinator: TangemPayBiometryNotSetPopupRoutable
    ) {
        self.biometryType = biometryType
        self.coordinator = coordinator
    }

    func setBiometry() {
        coordinator?.openBiometrySettings()
    }

    func dismiss() {
        coordinator?.closeBiometryNotSetPopup()
    }

    private struct Content {
        let icon: Image
        let title: String
        let description: String
        let buttonTitle: String
    }
}
