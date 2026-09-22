//
//  TangemPayChooseNetworkSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemPay
import TangemUI

@MainActor
final class TangemPayChooseNetworkSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var fastWayRows: [TangemPayNetworkRowViewData] = []
    @Published private(set) var otherWaysRows: [TangemPayNetworkRowViewData] = []

    private var networks: [TangemPayBalance.Network]
    private var rowStates: [Int: TangemPayNetworkRowViewData.State] = [:]
    private var orderServices: [Int: TangemPayNetworkContractOrderService] = [:]
    private var isRouting = false

    private let makeOrderService: () -> TangemPayNetworkContractOrderService
    private let refreshNetworks: () async -> [TangemPayBalance.Network]

    private weak var coordinator: TangemPayChooseNetworkSheetRoutable?

    init(
        networks: [TangemPayBalance.Network],
        makeOrderService: @escaping () -> TangemPayNetworkContractOrderService,
        refreshNetworks: @escaping () async -> [TangemPayBalance.Network],
        coordinator: TangemPayChooseNetworkSheetRoutable
    ) {
        self.networks = networks
        self.makeOrderService = makeOrderService
        self.refreshNetworks = refreshNetworks
        self.coordinator = coordinator

        rebuildRows()
    }

    func userDidTapRow(_ viewData: TangemPayNetworkRowViewData) {
        guard !isRouting else {
            return
        }

        switch viewData.row.action {
        case .receive(let input):
            openReceive(input: input)
        case .issueContract(let chainId):
            issueContract(chainId: chainId)
        case .explainOtherNetworks:
            isRouting = true
            coordinator?.chooseNetworkSheetRequestOtherNetworks()
        case nil:
            break
        }
    }

    func close() {
        coordinator?.closeChooseNetworkSheet()
    }
}

// MARK: - Private

private extension TangemPayChooseNetworkSheetViewModel {
    func rebuildRows() {
        let rows = TangemPayNetworkRowResolver.resolve(networks).map { row in
            TangemPayNetworkRowViewData(row: row, state: rowStates[row.id] ?? .idle)
        }

        fastWayRows = rows.filter { viewData in
            switch viewData.row.status {
            case .enabled, .notIssued: true
            case .disabled, .undefined: false
            }
        }

        otherWaysRows = rows.filter { viewData in
            switch viewData.row.status {
            case .disabled: true
            case .enabled, .notIssued, .undefined: false
            }
        }
    }

    func issueContract(chainId: Int) {
        guard rowStates[chainId] != .loading else {
            return
        }

        updateRowState(.loading, chainId: chainId)

        let service = makeOrderService()
        orderServices[chainId] = service

        service.start(chainId: chainId) { [weak self] result in
            runTask { @MainActor in
                self?.handle(result, chainId: chainId)
            }
        }
    }

    func handle(_ result: TangemPayNetworkContractOrderService.Result, chainId: Int) {
        orderServices[chainId] = nil

        switch result {
        case .completed(let depositAddress):
            runTask(in: self) { @MainActor viewModel in
                await viewModel.openReceive(chainId: chainId, depositAddress: depositAddress)
            }
        case .canceled, .failed, .timedOut:
            updateRowState(.error, chainId: chainId)
        }
    }

    func openReceive(chainId: Int, depositAddress: String?) async {
        if let input = receiveInput(chainId: chainId, depositAddress: depositAddress) {
            updateRowState(nil, chainId: chainId)
            openReceive(input: input)
            return
        }

        networks = await refreshNetworks()

        if let input = receiveInput(chainId: chainId, depositAddress: nil) {
            updateRowState(nil, chainId: chainId)
            openReceive(input: input)
        } else {
            updateRowState(.error, chainId: chainId)
        }
    }

    func openReceive(input: TangemPayReceiveSheetViewModel.Input) {
        isRouting = true
        coordinator?.chooseNetworkSheetRequestReceive(input: input)
    }

    func receiveInput(chainId: Int, depositAddress: String?) -> TangemPayReceiveSheetViewModel.Input? {
        guard let network = networks.first(where: { $0.chainId == chainId }),
              let address = depositAddress ?? network.depositAddress
        else {
            return nil
        }

        return TangemPayNetworkRowResolver.receiveInput(for: network, depositAddress: address)
    }

    func updateRowState(_ state: TangemPayNetworkRowViewData.State?, chainId: Int) {
        rowStates[chainId] = state
        rebuildRows()
    }
}
