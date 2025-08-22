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
import CombineExt
import TangemUI

final class SelectorReceiveAssetsViewModel: ObservableObject, Identifiable {
    // MARK: - UI Properties

    @Published var sections: [SelectorReceiveAssetsSection] = []
    @Published var notificationInputs: [NotificationViewInput] = []

    // MARK: - Private Properties

    private var bag: Set<AnyCancellable> = []

    private let interactor: SelectorReceiveAssetsInteractor
    private let analyticsLogger: SelectorReceiveAssetsAnalyticsLogger
    private let sectionFactory: SelectorReceiveAssetsSectionFactory

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
        interactor.update()
    }

    func onViewAppear() {
        let hasDomainNameAddresses = interactor.hasDomainNameAddresses()
        analyticsLogger.logSelectorReceiveAssetsScreenOpened(hasDomainNameAddresses)
    }

    // MARK: - Private Implementation

    func bind() {
        interactor
            .notificationsPublisher
            .receiveOnMain()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .addressTypesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, assets in
                viewModel.sectionFactory.makeSections(from: assets)
            }
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - FloatingSheetContentViewModel

extension SelectorReceiveAssetsViewModel: FloatingSheetContentViewModel {}
