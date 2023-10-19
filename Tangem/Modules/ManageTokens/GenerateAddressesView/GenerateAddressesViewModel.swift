//
//  GenerateAddressesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class GenerateAddressesViewModel: ObservableObject {
    // MARK: - Injected Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Properties

    @Published var numberOfNetworks: Int = 0
    @Published var currentWalletNumber: Int = 0
    @Published var totalWalletNumber: Int = 0
    @Published var hasPendingDerivation: Bool = false

    let didTapGenerate: () -> Void

    private var derivationManagers: [UserWalletId: Int] = [:] {
        didSet {
            guard !derivationManagers.filter({ $0.value > 0 }).isEmpty else {
                return
            }

            numberOfNetworks = derivationManagers.map { $0.value }.reduce(0, +)
            currentWalletNumber = derivationManagers.filter { $0.value > 0 }.count
            totalWalletNumber = userWalletRepository.userWallets.count
            hasPendingDerivation = numberOfNetworks > 0
        }
    }

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(_ didTapGenerate: @escaping () -> Void) {
        self.didTapGenerate = didTapGenerate

        bind()
    }

    // MARK: - Private Implementation

    func bind() {
        let publishers = userWalletRepository.models
            .compactMap { model -> AnyPublisher<(UserWalletId, Int), Never>? in
                if let derivationManager = model.userTokensManager.derivationManager {
                    return derivationManager.pendingDerivationsCount
                        .map { (model.userWalletId, $0) }
                        .eraseToAnyPublisher()
                }

                return nil
            }

        Publishers.MergeMany(publishers)
            .print()
            .receiveValue { [weak self] id, count in
                self?.derivationManagers[id] = count
            }
            .store(in: &bag)
    }
}
