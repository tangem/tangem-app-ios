//
//  MainScreenPromoSheetInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol MainScreenPromoSheetInteractor: Initializable {
    var presentationSettings: MainScreenPromoSheetPresentationSettings { get }

    func claimFirstMainScreenAppearance() -> Bool
}

final class CommonMainScreenPromoSheetInteractor {
    private let incomingActionManager: IncomingActionManaging

    private var isOpenedFromLink = false
    private var didClaimFirstMainScreenAppearance = false
    private var incomingActionsSubscription: AnyCancellable?

    init(incomingActionManager: IncomingActionManaging = InjectedValues[\.incomingActionManager]) {
        self.incomingActionManager = incomingActionManager
    }

    private func handle(_ action: IncomingAction) {
        switch action {
        case .navigation, .externalLink, .walletConnect:
            isOpenedFromLink = true
        case .start, .dismissSafari:
            break
        }
    }
}

// MARK: - MainScreenPromoSheetInteractor

extension CommonMainScreenPromoSheetInteractor: MainScreenPromoSheetInteractor {
    var presentationSettings: MainScreenPromoSheetPresentationSettings {
        MainScreenPromoSheetPresentationSettings(isOpenedFromLink: isOpenedFromLink)
    }

    func initialize() {
        incomingActionsSubscription = incomingActionManager.incomingActionsPublisher
            .withWeakCaptureOf(self)
            .sink { interactor, action in
                interactor.handle(action)
            }
    }

    func claimFirstMainScreenAppearance() -> Bool {
        guard !didClaimFirstMainScreenAppearance else {
            return false
        }

        didClaimFirstMainScreenAppearance = true
        return true
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var mainScreenPromoSheetInteractor: MainScreenPromoSheetInteractor {
        get { Self[Key.self] }
        set { Self[Key.self] = newValue }
    }

    private struct Key: InjectionKey {
        static var currentValue: MainScreenPromoSheetInteractor = CommonMainScreenPromoSheetInteractor()
    }
}
