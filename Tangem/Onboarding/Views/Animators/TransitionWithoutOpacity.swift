//
//  TransitionWithoutOpacity.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransitionWithoutOpacity: AnimatableModifier {
    var animatableData: CGFloat = 0
    init(_ x: CGFloat) {
        animatableData = x
    }
    func body(content: Content) -> some View {
        return content
    }
}
extension AnyTransition {
    static let withoutOpacity: AnyTransition = .modifier(active: TransitionWithoutOpacity(1), identity: TransitionWithoutOpacity(0))
}
