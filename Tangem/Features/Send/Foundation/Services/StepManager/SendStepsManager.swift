//
//  SendStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendStepsManager {
    var initialKeyboardState: Bool { get }
    var initialFlowActionType: SendFlowActionType { get }
    var initialStep: SendStep { get }

    var navigationBarSettings: SendStepNavigationBarSettings { get }
    var bottomBarSettings: SendStepBottomBarSettings { get }

    var shouldShowDismissAlert: Bool { get }

    func resetFlow()

    func performNext()
    func performBack()
    func performContinue()
    func performFinish()

    func set(output: SendStepsManagerOutput)
}

extension SendStepsManager {
    func resetFlow() {
        assertionFailure("Reset flow not implemented")
    }

    func performNext() {
        assertionFailure("Perform next not implemented")
    }

    func performBack() {
        assertionFailure("Perform back not implemented")
    }

    func performContinue() {
        assertionFailure("Perform continue not implemented")
    }

    func performFinish() {
        assertionFailure("Perform finish not implemented")
    }
}

struct SendStepNavigationBarSettings: Hashable {
    static let empty = SendStepNavigationBarSettings()

    let title: String?
    let subtitle: String?
    let leadingViewType: SendStepNavigationLeadingViewType?
    let trailingViewType: SendStepNavigationTrailingViewType?

    init(
        title: String? = nil,
        subtitle: String? = nil,
        leadingViewType: SendStepNavigationLeadingViewType? = nil,
        trailingViewType: SendStepNavigationTrailingViewType? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingViewType = leadingViewType
        self.trailingViewType = trailingViewType
    }
}

struct SendStepBottomBarSettings: Hashable {
    static let empty = SendStepBottomBarSettings(action: .close)

    let action: SendMainButtonType?
    let backButtonVisible: Bool
    let keyboardHiddenToolbarButtonVisible: Bool

    init(action: SendMainButtonType?, backButtonVisible: Bool = false, keyboardHiddenToolbarButtonVisible: Bool = false) {
        self.action = action
        self.backButtonVisible = backButtonVisible
        self.keyboardHiddenToolbarButtonVisible = keyboardHiddenToolbarButtonVisible
    }
}
