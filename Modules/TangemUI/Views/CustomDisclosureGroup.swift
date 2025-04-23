//
//  CustomDisclosureGroup.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct CustomDisclosureGroup<Prompt: View, ExpandedView: View>: View {
    private let actionOnClick: () -> Void
    private let animation: Animation?
    private let isExpanded: Bool
    private let transition: AnyTransition?
    private let prompt: Prompt
    private let expandedView: ExpandedView
    private let alignment: HorizontalAlignment

    public init(
        animation: Animation? = .default,
        isExpanded: Bool,
        transition: AnyTransition? = nil,
        actionOnClick: @escaping () -> Void,
        alignment: HorizontalAlignment = .center,
        prompt: () -> Prompt,
        expandedView: () -> ExpandedView
    ) {
        self.actionOnClick = actionOnClick
        self.isExpanded = isExpanded
        self.transition = transition
        self.animation = animation
        self.alignment = alignment
        self.prompt = prompt()
        self.expandedView = expandedView()
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            Button(action: { actionOnClick() }, label: {
                prompt
                    .contentShape(Rectangle())
            })

            if isExpanded {
                expandedView
                    .ifLet(transition) { view, transition in
                        view.transition(transition)
                    }
            }
        }
        .clipped()
        .drawingGroup()
    }
}
