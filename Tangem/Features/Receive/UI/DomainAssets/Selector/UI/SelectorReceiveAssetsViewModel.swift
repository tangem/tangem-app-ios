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
    private let sectionFactory: SelectorReceiveAssetsSectionFactory

    // MARK: - Init

    init(
        interactor: SelectorReceiveAssetsInteractor,
        sectionFactory: SelectorReceiveAssetsSectionFactory
    ) {
        self.interactor = interactor
        self.sectionFactory = sectionFactory

        bind()
    }

    func onViewAppear() {
        // [REDACTED_TODO_COMMENT]
        interactor.updateAssets()
    }

    // MARK: - Private Implementation

    func bind() {
        interactor
            .notificationsPublisher
            .receiveOnMain()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .receiveAssetsPublisher
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
