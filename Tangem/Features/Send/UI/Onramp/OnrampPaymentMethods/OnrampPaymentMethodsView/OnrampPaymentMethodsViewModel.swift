//
//  OnrampPaymentMethodsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemExpress
import TangemFoundation
import TangemUIUtils

final class OnrampPaymentMethodsViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var paymentMethods: [OnrampPaymentMethodRowViewData] = []
    @Published var selectedPaymentMethodID: String?
    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let interactor: OnrampPaymentMethodsInteractor
    private let analyticsLogger: SendOnrampPaymentMethodAnalyticsLogger
    private weak var coordinator: OnrampPaymentMethodsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: OnrampPaymentMethodsInteractor,
        analyticsLogger: SendOnrampPaymentMethodAnalyticsLogger,
        coordinator: OnrampPaymentMethodsRoutable
    ) {
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator

        bind()
    }

    func onAppear() {
        analyticsLogger.logOnrampPaymentMethodScreenOpened()
    }
}

// MARK: - Private

private extension OnrampPaymentMethodsViewModel {
    func bind() {
        Publishers.CombineLatest(
            interactor.paymentMethodsPublisher.removeDuplicates(),
            interactor.paymentMethodPublisher.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .receive(on: DispatchQueue.main)
        .sink { viewModel, args in
            let (paymentMethods, payment) = args
            viewModel.updateView(paymentMethods: paymentMethods, selectedPaymentMethod: payment)
        }
        .store(in: &bag)
    }

    func updateView(paymentMethods methods: [OnrampPaymentMethod], selectedPaymentMethod: OnrampPaymentMethod) {
        var paymentMethods: [OnrampPaymentMethodRowViewData] = []
        methods.forEach { method in
            let rowData = OnrampPaymentMethodRowViewData(
                id: method.id,
                name: method.name,
                iconURL: method.image,
                action: { [weak self] in
                    self?.analyticsLogger.logOnrampPaymentMethodChosen(paymentMethod: method)
                    self?.interactor.update(selectedPaymentMethod: method)
                    self?.updateView(paymentMethods: methods, selectedPaymentMethod: method)
                    self?.coordinator?.closeOnrampPaymentMethodsView()
                }
            )

            paymentMethods.append(rowData)

            if selectedPaymentMethod.id == method.id {
                selectedPaymentMethodID = method.id
            }
        }

        self.paymentMethods = paymentMethods
    }
}
