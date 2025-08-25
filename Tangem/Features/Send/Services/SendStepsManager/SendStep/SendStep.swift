//
//  SendStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendStep {
    var title: String? { get }
    var subtitle: String? { get }
    var shouldShowBottomOverlay: Bool { get }

    var type: SendStepType { get }
    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { get }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { get }
    var sendStepViewAnimatable: any SendStepViewAnimatable { get }

    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool

    func initialAppear()
    func willAppear(previous step: any SendStep)
    func willDisappear(next step: any SendStep)
}

extension SendStep {
    var subtitle: String? { .none }
    var shouldShowBottomOverlay: Bool { true }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool { true }

    func initialAppear() {}
    func willAppear(previous step: any SendStep) {}
    func willDisappear(next step: any SendStep) {}
}
