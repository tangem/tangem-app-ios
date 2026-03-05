//
//  SendCoordinatorStateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol SendCoordinatorStateProvider {
    func setup(autoupdatingTimer: AutoupdatingTimer)
}

class CommonSendCoordinatorStateProvider {
    @Injected(\.floatingSheetPresentingStateProvider)
    private var floatingSheetPresentingStateProvider: any FloatingSheetPresentingStateProvider

    private let state: CurrentValueSubject<SendCoordinatorState, Never> = .init(.root)
    private var autoupdatingTimerSubscription: AnyCancellable?

    func childPresented() {
        state.send(.child)
    }

    func childDismissed() {
        state.send(.root)
    }
}

// MARK: - SendCoordinatorStateProvider

extension CommonSendCoordinatorStateProvider: SendCoordinatorStateProvider {
    func setup(autoupdatingTimer: AutoupdatingTimer) {
        let isRootPublisher = state.map { $0 == .root }
        let isNoActiveSheetPublisher = floatingSheetPresentingStateProvider.hasPresentedSheetPublisher.map { !$0 }

        autoupdatingTimerSubscription = Publishers
            .CombineLatest(isRootPublisher, isNoActiveSheetPublisher)
            .map { $0 && $1 }
            .removeDuplicates()
            .sink { viewOnRoot in
                viewOnRoot ? autoupdatingTimer.resumeTimer() : autoupdatingTimer.pauseTimer()
            }
    }
}

enum SendCoordinatorState {
    case root
    /// State if coordinator has any presented child view / coordinator
    case child
}
