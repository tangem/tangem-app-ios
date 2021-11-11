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
                return Alert(title: Text("common_camera_denied_alert_title"),
                             message: Text("common_camera_denied_alert_message"),
                             primaryButton: Alert.Button.default(Text("common_camera_alert_button_settings"),
                                                                 action: { UIApplication.openSystemSettings() }),
                             secondaryButton: Alert.Button.default(Text("common_ok"),
                                                                   action: {}))
            }
    }
}
    
extension View {
    func cameraAccessDeniedAlert(_ isDisplayed: Binding<Bool>) -> some View {
        self.modifier(CameraAccessDeniedModifier(isDisplayed: isDisplayed))
    }
}
