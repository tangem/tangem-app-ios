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
                return Alert(title: Text(Localization.commonCameraDeniedAlertTitle),
                             message: Text(Localization.commonCameraDeniedAlertMessage),
                             primaryButton: Alert.Button.default(Text(Localization.commonCameraAlertButtonSettings),
                                                                 action: { UIApplication.openSystemSettings() }),
                             secondaryButton: Alert.Button.default(Text(Localization.commonOk),
                                                                   action: {}))
            }
    }
}

extension View {
    func cameraAccessDeniedAlert(_ isDisplayed: Binding<Bool>) -> some View {
        self.modifier(CameraAccessDeniedModifier(isDisplayed: isDisplayed))
    }
}
