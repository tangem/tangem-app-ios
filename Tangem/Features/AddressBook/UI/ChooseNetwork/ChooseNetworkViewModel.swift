//
//  ChooseNetworkViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import BlockchainSdk

protocol ChooseNetworkOutput: AnyObject {
    func chooseNetworkDidConfirm(_ selected: Set<BSDKBlockchain>)
}

protocol ChooseNetworkRoutable: AnyObject {
    func dismissChooseNetwork()
}

final class ChooseNetworkViewModel: ObservableObject, Identifiable {
    @Published var searchText: String = ""
    @Published private(set) var rows: [ChooseNetworkRowViewModel] = []
    var isDoneEnabled: Bool { selected.isNotEmpty }

    private let candidates: [BSDKBlockchain]
    private var selected: Set<BSDKBlockchain>
    private weak var output: ChooseNetworkOutput?
    private weak var routable: ChooseNetworkRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        candidates: Set<BSDKBlockchain>,
        preselected: Set<BSDKBlockchain>,
        output: ChooseNetworkOutput,
        routable: ChooseNetworkRoutable
    ) {
        self.candidates = candidates.sorted { $0.displayName < $1.displayName }
        selected = preselected
        self.output = output
        self.routable = routable

        rebuildRows()
        bind()
    }

    func done() {
        output?.chooseNetworkDidConfirm(selected)
        routable?.dismissChooseNetwork()
    }

    func close() {
        routable?.dismissChooseNetwork()
    }
}

// MARK: - Private

private extension ChooseNetworkViewModel {
    func bind() {
        $searchText
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: DispatchQueue.main, if: { !$0.isEmpty })
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.rebuildRows() }
            .store(in: &bag)
    }

    func toggle(_ blockchain: BSDKBlockchain) {
        if selected.contains(blockchain) {
            selected.remove(blockchain)
        } else {
            selected.insert(blockchain)
        }

        rebuildRows()
    }

    func rebuildRows() {
        let query = searchText.trimmed()

        let filtered = query.isEmpty ? candidates : candidates.filter { blockchain in
            blockchain.displayName.caseInsensitiveContains(query)
                || blockchain.currencySymbol.caseInsensitiveContains(query)
        }

        rows = filtered.map { blockchain in
            ChooseNetworkRowViewModel(
                blockchain: blockchain,
                isSelected: selected.contains(blockchain)
            ) { [weak self] in
                self?.toggle(blockchain)
            }
        }
    }
}
