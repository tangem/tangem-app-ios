//
//  HotOnboardingFlowStepTransformable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

protocol HotOnboardingFlowStepTransformable: AnyObject {
    var transformations: [TransformationModifier<AnyView>] { get set }
}

// MARK: - NavBar configurable

protocol HotOnboardingFlowStepNavBarConfigurable: HotOnboardingFlowStepTransformable {
    @discardableResult
    func configureNavBar(
        title: String?,
        leadingAction: HotOnboardingFlowNavBarAction?,
        trailingAction: HotOnboardingFlowNavBarAction?
    ) -> Self
}

extension HotOnboardingFlowStepNavBarConfigurable {
    @discardableResult
    func configureNavBar(
        title: String? = nil,
        leadingAction: HotOnboardingFlowNavBarAction? = nil,
        trailingAction: HotOnboardingFlowNavBarAction? = nil
    ) -> Self {
        if let title {
            transformations.append(TransformationModifier<AnyView> { view in
                AnyView(view.flowNavBar(title: title))
            })
        }

        if let leadingAction {
            transformations.append(TransformationModifier<AnyView> { view in
                AnyView(view.flowNavBar(leadingItem: leadingAction.view))
            })
        }

        if let trailingAction {
            transformations.append(TransformationModifier<AnyView> { view in
                AnyView(view.flowNavBar(trailingItem: trailingAction.view))
            })
        }

        return self
    }
}

// MARK: - ProgressBar configurable

protocol HotOnboardingFlowStepProgressBarConfigurable: HotOnboardingFlowStepTransformable {
    @discardableResult
    func configureProgressBar(value: Double) -> Self
}

extension HotOnboardingFlowStepProgressBarConfigurable {
    @discardableResult
    func configureProgressBar(value: Double) -> Self {
        transformations.append(TransformationModifier<AnyView> { view in
            AnyView(view.flowProgressBar(value: value))
        })
        return self
    }
}
