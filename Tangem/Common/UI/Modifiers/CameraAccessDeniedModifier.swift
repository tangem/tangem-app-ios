//
//  CameraAccessDeniedModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct CameraAccessDeniedModifier: ViewModifier {

    @Binding var isDisplayed: Bool

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isDisplayed) {
                return Alert(title: Text(L10n.commonCameraDeniedAlertTitle),
                             message: Text(L10n.commonCameraDeniedAlertMessage),
                             primaryButton: Alert.Button.default(Text(L10n.commonCameraAlertButtonSettings),
                                                                 action: { UIApplication.openSystemSettings() }),
                             secondaryButton: Alert.Button.default(Text(L10n.commonOk),
                                                                   action: {}))
            }
    }
}

extension View {
    func cameraAccessDeniedAlert(_ isDisplayed: Binding<Bool>) -> some View {
        self.modifier(CameraAccessDeniedModifier(isDisplayed: isDisplayed))
    }
}
