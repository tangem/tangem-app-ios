//
//  CustomDisclosureGroup.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

public struct CustomDisclosureGroup<Prompt: View, ExpandedView: View>: View {
    private let actionOnClick: () -> Void
    private let animation: Animation?
    private let isExpanded: Bool
    private let transition: AnyTransition?
    private let prompt: Prompt
    private let expandedView: ExpandedView

    public init(
        animation: Animation? = .default,
        isExpanded: Bool,
        transition: AnyTransition? = nil,
        actionOnClick: @escaping () -> Void,
        prompt: () -> Prompt,
        expandedView: () -> ExpandedView
    ) {
        self.actionOnClick = actionOnClick
        self.isExpanded = isExpanded
        self.transition = transition
        self.animation = animation
        self.prompt = prompt()
        self.expandedView = expandedView()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Button(action: { actionOnClick() }, label: {
                prompt
            })

            if isExpanded {
                expandedView
                    .modifier(ifLet: transition) { view, transition in
                        view.transition(transition)
                    }
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .drawingGroup()
    }
}
