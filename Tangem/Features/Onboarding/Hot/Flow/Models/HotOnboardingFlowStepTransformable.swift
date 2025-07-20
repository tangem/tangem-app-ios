//
//  HotOnboardingFlowStepTransformable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

protocol HotOnboardingFlowStepTransformable {
    var transformations: [TransformationModifier<AnyView>] { get set }
}

// MARK: - NavigationConfigurable

protocol HotOnboardingFlowStepNavigationConfigurable: HotOnboardingFlowStepTransformable {
    mutating func configureNavigation(
        title: String?,
        leadingAction: HotOnboardingFlowNavBarAction?,
        trailingAction: HotOnboardingFlowNavBarAction?
    )
}

extension HotOnboardingFlowStepNavigationConfigurable {
    mutating func configureNavigation(
        title: String? = nil,
        leadingAction: HotOnboardingFlowNavBarAction? = nil,
        trailingAction: HotOnboardingFlowNavBarAction? = nil
    ) {
        if let title {
            transformations.append(TransformationModifier<AnyView> { view in
                AnyView(view.flowNavBar(title: title))
            })
        }

        if let leadingAction {
            transformations.append(TransformationModifier<AnyView> { view in
                AnyView(view.flowNavBar(leadingItem: { Self.actionView(leadingAction) }))
            })
        }

        if let trailingAction {
            transformations.append(TransformationModifier<AnyView> { view in
                AnyView(view.flowNavBar(trailingItem: { Self.actionView(trailingAction) }))
            })
        }
    }

    @ViewBuilder
    private static func actionView(_ action: HotOnboardingFlowNavBarAction) -> some View {
        switch action {
        case .back(let handler):
            BackButton(
                height: OnboardingLayoutConstants.navbarSize.height,
                isVisible: true,
                isEnabled: true,
                action: handler
            )
        case .close(let handler):
            CloseButton(dismiss: handler)
                .padding(.leading, 16)
        }
    }
}

// MARK: - ProgressSetupable

protocol HotOnboardingFlowStepProgressSetupable: HotOnboardingFlowStepTransformable {
    mutating func setupProgress(_ value: @escaping () -> Double?)
}

extension HotOnboardingFlowStepProgressSetupable {
    mutating func setupProgress(_ value: @escaping () -> Double?) {
        transformations.append(TransformationModifier<AnyView> { view in
            AnyView(view.flowProgressBar(value: value()))
        })
    }
}
