//
//  SwappingApproveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError

final class SwappingApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var menuRowViewModel: DefaultMenuRowViewModel<SwappingApprovePolicy>?
    @Published var selectedAction: SwappingApprovePolicy = .unlimited
    @Published var feeRowViewModel: DefaultRowViewModel?
    @Published var isLoading: Bool = false
    @Published var errorAlert: AlertBinder?

    var tokenSymbol: String {
        sourceCurrency.symbol
    }

    // MARK: - Dependencies

    // [REDACTED_TODO_COMMENT]
    private let inputModel: SwappingPermissionInputModel
    private var sourceCurrency: Currency { inputModel.transactionData.sourceCurrency }
    private let transactionSender: SwappingTransactionSender
    private unowned let coordinator: SwappingApproveRoutable

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    private var feeLabel: String {
        let fiatFee = inputModel.fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        let formattedFee = inputModel.transactionData.fee.groupedFormatted()
        return "\(formattedFee) \(inputModel.transactionData.sourceBlockchain.symbol) (\(fiatFee))"
    }

    init(
        inputModel: SwappingPermissionInputModel,
        transactionSender: SwappingTransactionSender,
        coordinator: SwappingApproveRoutable
    ) {
        self.inputModel = inputModel
        self.transactionSender = transactionSender
        self.coordinator = coordinator

        setupView()
        bind()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
    }

    func didTapApprove() {
        // [REDACTED_TODO_COMMENT]
        let data = inputModel.transactionData

        Analytics.log(
            event: .swapButtonPermissionApprove,
            params: [
                .sendToken: data.sourceCurrency.symbol,
                .receiveToken: data.destinationCurrency.symbol,
            ]
        )

        Task {
            do {
                _ = try await transactionSender.sendTransaction(data)
                await didSendApproveTransaction(transactionData: data)
            } catch TangemSdkError.userCancelled {
                // Do nothing
            } catch {
                await runOnMain {
                    errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }

    func didTapCancel() {
        Analytics.log(.swapButtonPermissionCancel)
        coordinator.userDidCancel()
    }
}

// MARK: - Navigation

extension SwappingApproveViewModel {
    @MainActor
    func didSendApproveTransaction(transactionData: SwappingTransactionData) {
        // We have to waiting close the nfc view to close this permission view
        didBecomeActiveNotificationCancellable = NotificationCenter
            .default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.coordinator.didSendApproveTransaction(transactionData: transactionData)
            }
    }
}

// MARK: - Private

private extension SwappingApproveViewModel {
    func bind() {
        // [REDACTED_TODO_COMMENT]
        $selectedAction
            .dropFirst()
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.feeRowViewModel?.update(detailsType: .loader)
                self?.isLoading = true
            })
            .delay(for: 3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFeeAmount()
                self?.isLoading = false
            }
            .store(in: &bag)
    }

    func updateFeeAmount() {
        // [REDACTED_TODO_COMMENT]
        feeRowViewModel?.update(detailsType: .text(feeLabel))
    }

    func setupView() {
        menuRowViewModel = .init(
            title: Localization.swappingPermissionRowsAmount(tokenSymbol),
            actions: [
                SwappingApprovePolicy.unlimited,
                SwappingApprovePolicy.amount(inputModel.transactionData.sourceAmount),
            ]
        )

        feeRowViewModel = DefaultRowViewModel(
            title: Localization.sendFeeLabel,
            detailsType: .text(feeLabel)
        )
    }
}

extension SwappingApprovePolicy: DefaultMenuRowViewModelAction {
    public var id: Int { hashValue }

    public var title: String {
        switch self {
        case .amount:
            return Localization.swappingPermissionCurrentTransaction
        case .unlimited:
            return Localization.swappingPermissionUnlimited
        }
    }
}
