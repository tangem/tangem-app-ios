//
//  SelectorReceiveAssetsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemUI

final class SelectorReceiveAssetsViewModel: ObservableObject, Identifiable {
    // MARK: - UI Properties

    @Published var sections: [SelectorReceiveAssetsSection] = []
    @Published var notificationInputs: [NotificationViewInput] = []

    // MARK: - Private Properties

    private let interactor: SelectorReceiveAssetsInteractor
    private let analyticsLogger: SelectorReceiveAssetsAnalyticsLogger
    private let sectionFactory: SelectorReceiveAssetsSectionFactory
    private var logScreenOpenedSubscription: AnyCancellable?

    // MARK: - Init

    init(
        interactor: SelectorReceiveAssetsInteractor,
        analyticsLogger: SelectorReceiveAssetsAnalyticsLogger,
        sectionFactory: SelectorReceiveAssetsSectionFactory
    ) {
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.sectionFactory = sectionFactory

        bind()
    }

    func onViewAppear() {
        subscribeToLogScreenOpenedIfNeeded()
    }

    // MARK: - Private Implementation

    private func bind() {
        interactor
            .notificationsPublisher
            .receiveOnMain()
            .assign(to: &$notificationInputs)

        interactor
            .addressTypesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, assets in
                viewModel.sectionFactory.makeSections(from: assets)
            }
            .assign(to: &$sections)
    }

    private func subscribeToLogScreenOpenedIfNeeded() {
        guard logScreenOpenedSubscription == nil else {
            return
        }

        // One-time subscription (using `.first()` below) to log the screen opening event
        logScreenOpenedSubscription = interactor
            .addressTypesPublisher
            .filter { !$0.isEmpty } // Address types may be delivered asynchronously, so we wait until we have them to log the event
            .first()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.logScreenOpened()
            }
    }

    private func logScreenOpened() {
        let hasDomainNameAddresses = interactor.hasDomainNameAddresses()
        analyticsLogger.logSelectorReceiveAssetsScreenOpened(hasDomainNameAddresses)
    }
}

// MARK: - FloatingSheetContentViewModel

extension SelectorReceiveAssetsViewModel: FloatingSheetContentViewModel {}
