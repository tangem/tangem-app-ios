//
//  MainScreenPromoSheetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class MainScreenPromoSheetProvider {
    private let managers: [MainScreenPromoSheetManager]
    private let interactor: MainScreenPromoSheetInteractor
    private var decisionSubscription: AnyCancellable?

    init(
        managers: [MainScreenPromoSheetManager],
        interactor: MainScreenPromoSheetInteractor = InjectedValues[\.mainScreenPromoSheetInteractor]
    ) {
        self.managers = managers
        self.interactor = interactor
    }

    func onMainScreenAppear() {
        guard interactor.claimFirstMainScreenAppearance() else {
            return
        }

        let presentationSettings = interactor.presentationSettings
        let eligibleManagers = managers.filter { !interactor.hasShownSheet(managerId: $0.id) && $0.canHandlePresentation(presentationSettings) }

        guard !eligibleManagers.isEmpty else {
            return
        }

        decisionSubscription = eligibleManagers
            .map { $0.statePublisher.prepend(.preparing) }
            .combineLatest()
            .compactMap { Self.decision(for: $0, of: eligibleManagers) }
            .first()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, decision in
                provider.apply(decision)
            }
    }

    private func apply(_ decision: Decision) {
        switch decision {
        case .show(let manager):
            present(manager)
        case .skip(let manager, let reason):
            manager.logSkipped(reason)
        }
    }

    private func present(_ manager: MainScreenPromoSheetManager) {
        guard let appearancePublisher = manager.presentSheet() else {
            return
        }

        interactor.markSheetShownOnAppearance(appearancePublisher, managerId: manager.id, onShown: { manager.logShown() })
    }
}

// MARK: - Decision

private extension MainScreenPromoSheetProvider {
    enum Decision {
        case show(MainScreenPromoSheetManager)
        case skip(MainScreenPromoSheetManager, reason: MainScreenPromoSheetSkipReason)
    }

    static func decision(for states: [MainScreenPromoSheetManagerState], of managers: [MainScreenPromoSheetManager]) -> Decision? {
        for (manager, state) in zip(managers, states) {
            switch state {
            case .preparing:
                return nil
            case .ready:
                return .show(manager)
            case .unavailable:
                continue
            }
        }

        guard let manager = managers.first, case .unavailable(let reason)? = states.first else {
            return nil
        }

        return .skip(manager, reason: reason)
    }
}
