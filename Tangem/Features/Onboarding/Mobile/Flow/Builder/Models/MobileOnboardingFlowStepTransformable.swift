//
//  MobileOnboardingFlowStepTransformable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

protocol MobileOnboardingFlowStepTransformable: AnyObject {
    var transformations: [TransformationModifier<AnyView>] { get set }
}

// MARK: - NavBar configurable

protocol MobileOnboardingFlowStepNavBarConfigurable: MobileOnboardingFlowStepTransformable {
    @discardableResult
    func configureNavBar(
        title: String?,
        leadingAction: MobileOnboardingFlowNavBarAction?,
        trailingAction: MobileOnboardingFlowNavBarAction?
    ) -> Self
}

extension MobileOnboardingFlowStepNavBarConfigurable {
    @discardableResult
    func configureNavBar(
        title: String? = nil,
        leadingAction: MobileOnboardingFlowNavBarAction? = nil,
        trailingAction: MobileOnboardingFlowNavBarAction? = nil
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

protocol MobileOnboardingFlowStepProgressBarConfigurable: MobileOnboardingFlowStepTransformable {
    @discardableResult
    func configureProgressBar(value: Double) -> Self
}

extension MobileOnboardingFlowStepProgressBarConfigurable {
    @discardableResult
    func configureProgressBar(value: Double) -> Self {
        transformations.append(TransformationModifier<AnyView> { view in
            AnyView(view.flowProgressBar(value: value))
        })
        return self
    }
}
