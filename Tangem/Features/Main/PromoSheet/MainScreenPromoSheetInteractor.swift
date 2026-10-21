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
    func hasShownSheet(managerId: String) -> Bool
    func markSheetShownOnAppearance(_ appearancePublisher: AnyPublisher<Void, Never>, managerId: String, onShown: @escaping () -> Void)
}

final class CommonMainScreenPromoSheetInteractor {
    private let incomingActionManager: IncomingActionManaging

    private var isOpenedFromLink = false
    private var didClaimFirstMainScreenAppearance = false
    private var incomingActionsSubscription: AnyCancellable?
    private var shownSheetSubscription: AnyCancellable?

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

    func hasShownSheet(managerId: String) -> Bool {
        AppSettings.shared.shownMainScreenPromoSheetIds.contains(managerId)
    }

    func markSheetShownOnAppearance(_ appearancePublisher: AnyPublisher<Void, Never>, managerId: String, onShown: @escaping () -> Void) {
        shownSheetSubscription = appearancePublisher
            .first()
            .withWeakCaptureOf(self)
            .sink { interactor, _ in
                interactor.saveShownSheet(managerId: managerId)
                onShown()
            }
    }

    private func saveShownSheet(managerId: String) {
        AppSettings.shared.shownMainScreenPromoSheetIds.insert(managerId)
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
