//
//  HeightScaleModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NotificationTransitionModifier: ViewModifier {
    let height: CGFloat

    private let verticalMovementOffset: CGFloat = 75

    func body(content: Content) -> some View {
        content.scaleEffect(y: height, anchor: .top)
            // Adding up movement to slightly hide vertical scaling effect and make it little bit more natural
            .offset(y: -verticalMovementOffset + verticalMovementOffset * height)
    }
}

extension AnyTransition {
    static var notificationTransition: AnyTransition {
        AnyTransition.modifier(
            active: NotificationTransitionModifier(height: 0.6),
            identity: NotificationTransitionModifier(height: 1)
        )
        .animation(.easeInOut(duration: 0.3))
        .combined(with: .asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.4)),
            removal: .opacity.animation(.easeOut(duration: 0.3))
        ))
    }
}
