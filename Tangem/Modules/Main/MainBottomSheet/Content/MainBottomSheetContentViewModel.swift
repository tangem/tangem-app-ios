//
//  MainBottomSheetContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainBottomSheetContentViewModel: ObservableObject {
    // MARK: - ViewModel

    @Published var manageTokensViewModel: ManageTokensViewModel?

    // MARK: - Private

    private let coordinator: MainBottomSheetContentRoutable
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        searchTextPublisher: some Publisher<String, Never>,
        coordinator: MainBottomSheetContentRoutable
    ) {
        self.coordinator = coordinator

        manageTokensViewModel = .init(coordinator: coordinator)

        bind(searchTextPublisher: searchTextPublisher)
    }

    // MARK: - Private Implementation

    private func bind(searchTextPublisher: some Publisher<String, Never>) {
        searchTextPublisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.manageTokensViewModel?.fetch(with: value)
            }
            .store(in: &bag)
    }
}
