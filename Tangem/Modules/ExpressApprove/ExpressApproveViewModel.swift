//
//  ExpressApproveViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 11.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import UIKit
import enum TangemSdk.TangemSdkError
import struct BlockchainSdk.Fee

final class ExpressApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var subtitle: String

    @Published var menuRowViewModel: DefaultMenuRowViewModel<ExpressApprovePolicy>?
    @Published var selectedAction: ExpressApprovePolicy
    @Published var feeRowViewModel: DefaultRowViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private let feeFormatter: FeeFormatter
    private let logger: Logger
    private let approveService: ApproveService
    private weak var coordinator: ExpressApproveRoutable?

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        feeFormatter: FeeFormatter,
        logger: Logger,
        approveService: ApproveService,
        coordinator: ExpressApproveRoutable
    ) {
        self.feeFormatter = feeFormatter
        self.logger = logger
        self.approveService = approveService
        self.coordinator = coordinator

        tokenItem = settings.tokenItem
        feeTokenItem = settings.feeTokenItem

        selectedAction = settings.selectedPolicy
        subtitle = settings.subtitle
        menuRowViewModel = .init(
            title: Localization.givePermissionRowsAmount(settings.tokenItem.currencySymbol),
            actions: [.unlimited, .specified]
        )

        feeRowViewModel = DefaultRowViewModel(title: Localization.commonNetworkFeeTitle, detailsType: .none)
        updateView(state: approveService.approveFeeValue)
        bind()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
    }

    func didTapApprove() {
        sendApproveTransaction()
    }

    func didTapCancel() {
        Analytics.log(.swapButtonPermissionCancel)
        coordinator?.userDidCancel()
    }
}

// MARK: - Navigation

extension ExpressApproveViewModel {
    @MainActor
    func didSendApproveTransaction() {
        // We have to wait when the iOS close the nfc view that close this permission view
        didBecomeActiveNotificationCancellable = NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.coordinator?.didSendApproveTransaction()
            }
    }
}

// MARK: - Private

private extension ExpressApproveViewModel {
    func bind() {
        approveService.approveFeeValuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.updateView(state: state)
            }
            .store(in: &bag)

        $selectedAction
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, policy in
                viewModel.approveService.updateApprovePolicy(policy: policy)
            }
            .store(in: &bag)
    }

    func updateView(state: LoadingValue<Fee>) {
        switch state {
        case .loaded(let fee):
            updateFeeAmount(fee: fee)
            isLoading = false
            mainButtonIsDisabled = false
        case .loading:
            feeRowViewModel?.update(detailsType: .loader)
            isLoading = true
            mainButtonIsDisabled = false
        case .failedToLoad(let error):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeAmount(fee: Fee) {
        let formatted = feeFormatter.format(fee: fee.amount.value, tokenItem: feeTokenItem)
        feeRowViewModel?.update(detailsType: .text(formatted))
    }

    func sendApproveTransaction() {
        runTask(in: self) { viewModel in
            do {
                try await viewModel.approveService.sendApproveTransaction()
                await viewModel.didSendApproveTransaction()
            } catch {
                viewModel.logger.error(error)
                await runOnMain {
                    viewModel.errorAlert = .init(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }
}

extension ExpressApproveViewModel {
    struct Settings {
        let subtitle: String // Localization.givePermissionSwapSubtitle(providerName, currencySymbol)
        let tokenItem: TokenItem
        let feeTokenItem: TokenItem

        let selectedPolicy: ExpressApprovePolicy
    }
}

extension ExpressApprovePolicy: DefaultMenuRowViewModelAction {
    public var id: Int { hashValue }

    public var title: String {
        switch self {
        case .specified:
            return Localization.givePermissionCurrentTransaction
        case .unlimited:
            return Localization.givePermissionUnlimited
        }
    }
}
