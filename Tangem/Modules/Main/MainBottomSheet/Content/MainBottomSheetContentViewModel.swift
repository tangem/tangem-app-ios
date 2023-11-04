//
//  MainBottomSheetContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// A temporary entity for integration and testing, subject to change.
final class MainBottomSheetContentViewModel: ObservableObject {
    // MARK: - ViewModel

    @Published var manageTokensViewModel: ManageTokensViewModel?

    // MARK: - Private

    private let coordinator: MainBottomSheetCoordinator // [REDACTED_TODO_COMMENT]
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        enteredSearchTextPublisher: some Publisher<String, Never>,
        coordinator: MainBottomSheetCoordinator // [REDACTED_TODO_COMMENT]
    ) {
        self.coordinator = coordinator
        manageTokensViewModel = .init(coordinator: coordinator)

        bind(enteredSearchTextPublisher: enteredSearchTextPublisher)
    }

    // MARK: - Private Implementation

    private func bind(enteredSearchTextPublisher: some Publisher<String, Never>) {
        // [REDACTED_TODO_COMMENT]
        enteredSearchTextPublisher
            .sink { enteredSearchText in
                print("enteredSearchText:", enteredSearchText)
            }
            .store(in: &bag)

//        $enteredSearchText
//            .dropFirst()
//            .debounce(for: 0.5, scheduler: DispatchQueue.main)
//            .removeDuplicates()
//            .sink { [weak self] string in
//                self?.manageTokensViewModel?.fetch(searchText: string)
//            }
//            .store(in: &bag)
    }
}
