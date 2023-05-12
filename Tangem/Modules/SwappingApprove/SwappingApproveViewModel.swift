//
//  SwappingApproveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import UIKit
import enum TangemSdk.TangemSdkError

final class SwappingApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var menuRowViewModel: DefaultMenuRowViewModel<SwappingApprovePolicy>?
    @Published var selectedAction: SwappingApprovePolicy
    @Published var feeRowViewModel: DefaultRowViewModel?

    @Published var isLoading: Bool = false
    @Published var mainButtonIsDisabled: Bool = false
    @Published var errorAlert: AlertBinder?

    var tokenSymbol: String {
        swappingInteractor.getSwappingItems().source.symbol
    }

    // MARK: - Dependencies

    private let transactionSender: SwappingTransactionSender
    private let swappingInteractor: SwappingInteractor
    private let fiatRatesProvider: FiatRatesProviding
    private unowned let coordinator: SwappingApproveRoutable

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []
    private var transactionData: SwappingTransactionData? {
        guard case .available(_, let data) = swappingInteractor.getAvailabilityState() else {
            AppLog.shared.debug("TransactionData for approve isn't found")
            return nil
        }

        return data
    }

    init(
        transactionSender: SwappingTransactionSender,
        swappingInteractor: SwappingInteractor,
        fiatRatesProvider: FiatRatesProviding,
        coordinator: SwappingApproveRoutable
    ) {
        self.transactionSender = transactionSender
        self.swappingInteractor = swappingInteractor
        self.fiatRatesProvider = fiatRatesProvider
        self.coordinator = coordinator

        self.selectedAction = swappingInteractor.getSwappingApprovePolicy()
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
        guard let data = transactionData else {
            AppLog.shared.debug("TransactionData for approve isn't found")
            showNoDataErrorAlert()
            return
        }

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
        swappingInteractor.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle, .preview:
                    self?.feeRowViewModel?.update(detailsType: .text("0.0"))
                    self?.isLoading = false
                    self?.mainButtonIsDisabled = true
                case .loading:
                    self?.feeRowViewModel?.update(detailsType: .loader)
                    self?.isLoading = true
                    self?.mainButtonIsDisabled = false
                case .available(_, let data):
                    self?.updateFeeAmount(for: data)
                    self?.isLoading = false
                    self?.mainButtonIsDisabled = false
                case .requiredRefresh(let error):
                    self?.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
                    self?.isLoading = false
                    self?.mainButtonIsDisabled = true
                }
            }
            .store(in: &bag)

        $selectedAction
            .dropFirst()
            .sink { [weak self] action in
                self?.swappingInteractor.update(approvePolicy: action)
            }
            .store(in: &bag)
    }

    func format(fee: Decimal, fiatFee: Decimal) -> String {
        let feeFormatted = fee.groupedFormatted()
        let fiatFeeFormatted = fiatFee.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)

        return "\(feeFormatted) \(tokenSymbol) (\(fiatFeeFormatted))"
    }

    func updateFeeAmount(for transactionData: SwappingTransactionData) {
        Task {
            do {
                let fee = transactionData.fee
                let fiatFee = try await fiatRatesProvider.getFiat(for: transactionData.sourceBlockchain, amount: fee)
                let fullFeeString = format(fee: fee, fiatFee: fiatFee)
                await runOnMain {
                    feeRowViewModel?.update(detailsType: .text(fullFeeString))
                }
            } catch {
                AppLog.shared.error(error)

                await runOnMain {
                    feeRowViewModel?.update(detailsType: .text("0.0"))
                }
            }
        }
    }

    func setupView() {
        guard let transactionData = transactionData else {
            AppLog.shared.debug("TransactionData for approve isn't found")
            return
        }

        menuRowViewModel = .init(
            title: Localization.swappingPermissionRowsAmount(tokenSymbol),
            actions: [
                SwappingApprovePolicy.unlimited,
                SwappingApprovePolicy.amount(transactionData.sourceAmount),
            ]
        )

        let fee = transactionData.fee
        let sourceBlockchain = transactionData.sourceBlockchain

        if fiatRatesProvider.hasRates(for: sourceBlockchain),
           let fiatFee = fiatRatesProvider.getSyncFiat(for: sourceBlockchain, amount: fee) {
            let feeLabel = format(fee: fee, fiatFee: fiatFee)
            feeRowViewModel = DefaultRowViewModel(
                title: Localization.sendFeeLabel,
                detailsType: .text(feeLabel)
            )
        } else {
            feeRowViewModel = DefaultRowViewModel(
                title: Localization.sendFeeLabel,
                detailsType: .loader
            )

            updateFeeAmount(for: transactionData)
        }
    }

    func showNoDataErrorAlert() {
        errorAlert = AlertBuilder.makeOkErrorAlert(message: CommonError.noData.localizedDescription) { [weak self] in
            self?.coordinator.userDidCancel()
        }
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
