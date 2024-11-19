//
//  ActionButtonViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonViewModel: ObservableObject, Identifiable {
    @Published private(set) var presentationState: ActionButtonPresentationState = .unexplicitLoading

    let model: ActionButtonModel

    private let didTapAction: () -> Void

    init(model: ActionButtonModel, didTapAction: @escaping () -> Void) {
        self.model = model
        self.didTapAction = didTapAction
    }

    @MainActor
    func tap() {
        switch presentationState {
        case .loading:
            break
        case .unexplicitLoading:
            updateState(to: .loading)
        case .idle:
            didTapAction()
        }
    }

    @MainActor
    func updateState(to state: ActionButtonPresentationState) {
        presentationState = state
    }
}
