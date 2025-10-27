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
    var shouldShowBottomOverlay: Bool { get }

    var type: SendStepType { get }

    var isValidPublisher: AnyPublisher<Bool, Never> { get }
    var isUpdatingPublisher: AnyPublisher<Bool, Never> { get }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool

    func initialAppear()
    func willAppear(previous step: any SendStep)
    func willDisappear(next step: any SendStep)
}

extension SendStep {
    var shouldShowBottomOverlay: Bool { false }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool { true }

    func initialAppear() {}
    func willAppear(previous step: any SendStep) {}
    func willDisappear(next step: any SendStep) {}
}
