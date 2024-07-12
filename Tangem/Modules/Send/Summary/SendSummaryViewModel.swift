//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendSummaryViewModelSetupable: AnyObject {
    func setup(sendDestinationInput: SendDestinationInput)
    func setup(sendAmountInput: SendAmountInput)
    func setup(sendFeeInteractor: SendFeeInteractor)
}

class SendSummaryViewModel: ObservableObject, Identifiable {
    @Published var editableType: EditableType
    @Published var canEditFee: Bool = false

    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: SendAmountSummaryViewData?
    @Published var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
    @Published var deselectedFeeRowViewModels: [FeeRowViewModel] = []

    @Published var animatingDestinationOnAppear = false
    @Published var animatingAmountOnAppear = false
    @Published var animatingFeeOnAppear = false
    @Published var showHint = false

    @Published var alert: AlertBinder?
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    @Published var transactionDescription: String?
    @Published var transactionDescriptionIsVisible: Bool = false

    let addressTextViewHeightModel: AddressTextViewHeightModel
    var didProperlyDisappear: Bool = true

    var canEditAmount: Bool { editableType == .editable }
    var canEditDestination: Bool { editableType == .editable }

    private let tokenItem: TokenItem
    private let interactor: SendSummaryInteractor
    private let notificationManager: NotificationManager
    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    weak var router: SendSummaryStepsRoutable?

    private var isVisible = false
    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        interactor: SendSummaryInteractor,
        notificationManager: NotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sectionViewModelFactory: SendSummarySectionViewModelFactory
    ) {
        editableType = settings.editableType
        tokenItem = settings.tokenItem

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.sectionViewModelFactory = sectionViewModelFactory

        bind()
    }

    func setupAnimations(previousStep: SendStepType) {
        switch previousStep {
        case .destination:
            animatingAmountOnAppear = true
            animatingFeeOnAppear = true
        case .amount:
            animatingDestinationOnAppear = true
            animatingFeeOnAppear = true
        case .fee:
            animatingDestinationOnAppear = true
            animatingAmountOnAppear = true
        default:
            break
        }

        showHint = false
        transactionDescriptionIsVisible = false
    }

    func onAppear() {
        isVisible = true

        selectedFeeSummaryViewModel?.setAnimateTitleOnAppear(true)

        withAnimation(SendView.Constants.defaultAnimation) {
            self.animatingDestinationOnAppear = false
            self.animatingAmountOnAppear = false
            self.animatingFeeOnAppear = false
            self.transactionDescriptionIsVisible = self.transactionDescription != nil
        }

        Analytics.log(.sendConfirmScreenOpened)

        // For the sake of simplicity we're assuming that notifications aren't going to be created after the screen has been displayed
        if notificationInputs.isEmpty, !AppSettings.shared.userDidTapSendScreenSummary {
            withAnimation(SendView.Constants.defaultAnimation.delay(SendView.Constants.animationDuration * 2)) {
                self.showHint = true
            }
        }
    }

    func onDisappear() {
        isVisible = false
    }

    func userDidTapDestination() {
        didTapSummary()
        router?.summaryStepRequestEditDestination()
    }

    func userDidTapAmount() {
        didTapSummary()
        router?.summaryStepRequestEditAmount()
    }

    func userDidTapFee() {
        didTapSummary()
        router?.summaryStepRequestEditFee()
    }

    private func didTapSummary() {
        AppSettings.shared.userDidTapSendScreenSummary = true
        showHint = false
    }

    private func bind() {
        interactor
            .transactionDescription
            .receive(on: DispatchQueue.main)
            .assign(to: \.transactionDescription, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .sink { [weak self] notificationInputs in
                self?.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }
}

// MARK: - SendSummaryViewModelSetupable

extension SendSummaryViewModel: SendSummaryViewModelSetupable {
    func setup(sendDestinationInput input: SendDestinationInput) {
        Publishers.CombineLatest(input.destinationPublisher, input.additionalFieldPublisher)
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (destination, additionalField) = args
                return viewModel.sectionViewModelFactory.makeDestinationViewTypes(
                    address: destination.value,
                    additionalField: additionalField
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)
    }

    func setup(sendAmountInput input: SendAmountInput) {
        input.amountPublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, amount in
                guard let formattedAmount = amount?.format(currencySymbol: viewModel.tokenItem.currencySymbol),
                      let formattedAlternativeAmount = amount?.formatAlternative(currencySymbol: viewModel.tokenItem.currencySymbol) else {
                    return nil
                }

                return viewModel.sectionViewModelFactory.makeAmountViewData(
                    amount: formattedAmount,
                    amountAlternative: formattedAlternativeAmount
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.amountSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func setup(sendFeeInteractor interactor: SendFeeInteractor) {
        interactor
            .feesPublisher
            .map { feeValues in
                let multipleFeeOptions = feeValues.count > 1
                let hasError = feeValues.contains { $0.value.error != nil }

                return multipleFeeOptions && !hasError
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.canEditFee, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(interactor.feesPublisher, interactor.selectedFeePublisher)
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, args in
                let (feeValues, selectedFee) = args
                var selectedFeeSummaryViewModel: SendFeeSummaryViewModel?
                var deselectedFeeRowViewModels: [FeeRowViewModel] = []

                for feeValue in feeValues {
                    if feeValue.option == selectedFee?.option {
                        selectedFeeSummaryViewModel = viewModel.sectionViewModelFactory.makeFeeViewData(from: feeValue)
                    } else {
                        let model = viewModel.sectionViewModelFactory.makeDeselectedFeeRowViewModel(from: feeValue)
                        deselectedFeeRowViewModels.append(model)
                    }
                }

                viewModel.selectedFeeSummaryViewModel = selectedFeeSummaryViewModel
                viewModel.deselectedFeeRowViewModels = deselectedFeeRowViewModels
            }
            .store(in: &bag)
    }
}

extension SendSummaryViewModel {
    struct Settings {
        let tokenItem: TokenItem
        let editableType: EditableType
    }

    enum EditableType: Hashable {
        case disable
        case editable
    }
}
