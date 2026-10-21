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
    private let experimentService: ExperimentService
    private let selectedUserWalletId: () -> UserWalletId?
    private weak var host: MainScreenPromoSheetHost?
    private var decisionSubscription: AnyCancellable?

    init(
        managers: [MainScreenPromoSheetManager],
        host: MainScreenPromoSheetHost,
        interactor: MainScreenPromoSheetInteractor = InjectedValues[\.mainScreenPromoSheetInteractor],
        experimentService: ExperimentService = InjectedValues[\.experimentService],
        selectedUserWalletId: @escaping () -> UserWalletId? = { InjectedValues[\.userWalletRepository].selectedModel?.userWalletId }
    ) {
        self.managers = managers
        self.host = host
        self.interactor = interactor
        self.experimentService = experimentService
        self.selectedUserWalletId = selectedUserWalletId
    }

    func onMainScreenAppear(isPushRequestScheduled: Bool) {
        guard interactor.claimFirstMainScreenAppearance() else {
            return
        }

        let presentationSettings = interactor.presentationSettings
        let eligibleManagers = managers.filter { !interactor.hasShownSheet(managerId: $0.id) && $0.canHandlePresentation(presentationSettings) }

        guard let firstManager = eligibleManagers.first, let host else {
            return
        }

        guard !isPushRequestScheduled else {
            firstManager.logSkipped(.surfaceBusy)
            return
        }

        let surfaceBusyPublisher = Publishers.MergeMany(host.busySurfacePublishers)
            .filter { $0 }
            .map { _ in Decision.skip(firstManager, reason: .surfaceBusy) }

        let sourcesDecisionPublisher = eligibleManagers
            .map { $0.statePublisher.receiveOnMain().prepend(.preparing) }
            .combineLatest()
            .compactMap { Self.decision(for: $0, of: eligibleManagers) }

        decisionSubscription = surfaceBusyPublisher
            .merge(with: sourcesDecisionPublisher)
            .first()
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
        guard
            let userWalletId = selectedUserWalletId(),
            MainActor.assumeIsolated({ experimentService.hasFetchedVariants(for: userWalletId) })
        else {
            manager.logSkipped(.variantNotReady)
            return
        }

        guard let appearancePublisher = manager.presentSheet(experimentVariant: experimentService.variant(manager.experimentKey)?.value) else {
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
