//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BigInt
import BlockchainSdk

class CommonSendFeeProvider: SendFeeProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        walletModel.getFee(amount: amount, destination: destination)
    }
}

protocol SendFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
}

class CommonSendFeeProcessor {
    private weak var input: SendFeeProcessorInput?
    private let provider: SendFeeProvider
    private let customFeeService: CustomFeeService?

    private let _fees: CurrentValueSubject<[FeeOption: LoadingValue<BlockchainSdk.Fee>], Never> = .init([:])
    private var _customFee: BlockchainSdk.Fee?

    init(
        input: SendFeeProcessorInput,
        provider: SendFeeProvider,
        customFeeServiceFactory: CustomFeeServiceFactory
    ) {
        self.input = input
        self.provider = provider

        customFeeService = customFeeServiceFactory.makeService(input: self, output: self)
        bind()
    }

    func bind() {}
}

// MARK: - CustomFeeServiceInput, CustomFeeServiceOutput

extension CommonSendFeeProcessor: CustomFeeServiceInput, CustomFeeServiceOutput {
    var customFee: BlockchainSdk.Fee? {
        _customFee
    }
    
    var cryptoAmountPublisher: AnyPublisher<BlockchainSdk.Amount?, Never> {
        <#code#>
    }
    
    var destinationPublisher: AnyPublisher<SendAddress?, Never> {
        <#code#>
    }
    
    var feeValuePublisher: AnyPublisher<BlockchainSdk.Fee?, Never> {
        <#code#>
    }
    
    func setCustomFee(_ customFee: BlockchainSdk.Fee?) {
        _customFee = customFee
    }
}

extension CommonSendFeeProcessor: SendFeeProcessor {
    func feesPublisher() -> AnyPublisher<[FeeOption: LoadingValue<BlockchainSdk.Fee>], Never> {
        _fees.eraseToAnyPublisher()
    }

    func userDidUpdateCustomFee(value: Decimal) {
        guard let customFeeService = customFeeService as? EditableCustomFeeService else {
            return
        }

        customFeeService.setCustomFee(value: value)
    }
}

protocol SendFeeProcessorInput: AnyObject {
    func updateFee()
}

protocol SendFeeProcessor {
    func feesPublisher() -> AnyPublisher<[FeeOption: LoadingValue<Fee>], Never>

    func userDidUpdateCustomFee(value: Decimal)
}

protocol SendFeeInput: AnyObject {
    var selectedFee: FeeOption { get }
}

protocol SendFeeOutput: AnyObject {
    func feeDidChanged(fee: Fee)
}

protocol SendFeeViewModelInput {
    var selectedFeeOption: FeeOption { get }
//    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }

    var customFeePublisher: AnyPublisher<Fee?, Never> { get }

    var canIncludeFeeIntoAmount: Bool { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    func didSelectFeeOption(_ feeOption: FeeOption)
}

class SendFeeViewModel: ObservableObject {
    @Published private(set) var selectedFeeOption: FeeOption?
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []
    @Published private(set) var showCustomFeeFields: Bool = false
    @Published private(set) var deselectedFeeViewsVisible: Bool = false
    @Published var animatingAuxiliaryViewsOnAppear: Bool = false

    var feeSelectorFooterText: String {
        Localization.commonFeeSelectorFooter("[\(Localization.commonReadMore)](\(feeExplanationUrl.absoluteString))")
    }

    var didProperlyDisappear = true

    var lastFeeOption: FeeOption? { feeOptions.last }

    private(set) var customFeeModels: [SendCustomFeeInputFieldModel] = []

//    @Published private var isFeeIncluded: Bool = false

    @Published private(set) var feeLevelsNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var customFeeNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var feeCoverageNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    private let tokenItem: TokenItem
    private let feeOptions: [FeeOption]

    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?
    private weak var router: SendFeeRoutable?

    private let processor: SendFeeProcessor
    private let notificationManager: SendNotificationManager

//    private let walletInfo: SendWalletInfo
//    private let customFeeService: CustomFeeService?
//    private let customFeeInFiat = CurrentValueSubject<String?, Never>("")
    // Save this values to compare it when the focus changed and send analytics
//    private var customFeeValue: Decimal?
//    private var customFeeBeforeEditing: Decimal?

    private let feeExplanationUrl = TangemBlogUrlBuilder().url(post: .fee)
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    private var bag: Set<AnyCancellable> = []

    private lazy var feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: balanceFormatter,
        balanceConverter: balanceConverter
    )

    init(
        initial: Initial,
        input: SendFeeInput,
        output: SendFeeOutput,
        router: SendFeeRoutable,
        processor: SendFeeProcessor,
        notificationManager: SendNotificationManager
    ) {
        tokenItem = initial.tokenItem
        feeOptions = initial.feeOptions

        self.input = input
        self.output = output
        self.router = router
        self.processor = processor
        self.notificationManager = notificationManager

//        self.customFeeService = customFeeService
//        self.walletInfo = walletInfo
//        feeOptions = input.feeOptions
//        selectedFeeOption = input.selectedFeeOption

//        if feeOptions.contains(.custom) {
//            createCustomFeeModels()
//        }

//        feeRowViewModels = makeFeeRowViewModels([:])

        setupView()
        bind()
    }

    func onAppear() {
        let deselectedFeeViewAppearanceDelay = SendView.Constants.animationDuration / 3
        DispatchQueue.main.asyncAfter(deadline: .now() + deselectedFeeViewAppearanceDelay) {
            withAnimation(SendView.Constants.defaultAnimation) {
                self.deselectedFeeViewsVisible = true
            }
        }

        if animatingAuxiliaryViewsOnAppear {
            Analytics.log(.sendScreenReopened, params: [.source: .fee])
        } else {
            Analytics.log(.sendFeeScreenOpened)
        }
    }

    func onDisappear() {
        deselectedFeeViewsVisible = false
    }

    func openFeeExplanation() {
        router?.openFeeExplanation(url: feeExplanationUrl)
    }

    /*
     private func createCustomFeeModels() {
         guard let customFeeService else { return }

         let editableCustomFeeService = customFeeService as? EditableCustomFeeService
         let onCustomFeeFieldChange: ((Decimal?) -> Void)?
         if let editableCustomFeeService {
             onCustomFeeFieldChange = { [weak self] value in
                 self?.customFeeValue = value
                 editableCustomFeeService.setCustomFee(value: value)
             }
         } else {
             onCustomFeeFieldChange = nil
         }

         let customFeeModel = SendCustomFeeInputFieldModel(
             title: Localization.sendMaxFee,
             amountPublisher: input.customFeePublisher.decimalPublisher,
             disabled: editableCustomFeeService == nil,
             fieldSuffix: walletInfo.feeCurrencySymbol,
             fractionDigits: walletInfo.feeFractionDigits,
             amountAlternativePublisher: customFeeInFiat.eraseToAnyPublisher(),
             footer: customFeeService.customFeeDescription,
             onFieldChange: onCustomFeeFieldChange
         ) { [weak self] focused in
             self?.onCustomFeeChanged(focused)
         }

         customFeeModels = [customFeeModel] + customFeeService.inputFieldModels()
     }
     */

    private func setupView() {
        updateViewModels(values: feeOptions.reduce(into: [:]) { $0[$1] = .loading })
    }

    private func bind() {
        processor.feesPublisher()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, values in
                viewModel.updateViewModels(values: values)
            }
            .store(in: &bag)

//        input
//            .customFeePublisher
//            .withWeakCaptureOf(self)
//            .map { (self, customFee) -> String? in
//                guard
//                    let customFee,
//                    let feeCurrencyId = self.walletInfo.feeCurrencyId,
//                    let fiatFee = self.balanceConverter.convertToFiat(customFee.amount.value, currencyId: feeCurrencyId)
//                else {
//                    return nil
//                }
//
//                return self.balanceFormatter.formatFiatBalance(fiatFee)
//            }
//            .withWeakCaptureOf(self)
//            .sink { (self, customFeeInFiat) in
//                self.customFeeInFiat.send(customFeeInFiat)
//            }
//            .store(in: &bag)

//        input.isFeeIncludedPublisher
//            .assign(to: \.isFeeIncluded, on: self, ownership: .weak)
//            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeLevels)
            .assign(to: \.feeLevelsNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .customFee)
            .assign(to: \.customFeeNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .feeIncluded)
            .assign(to: \.feeCoverageNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateViewModels(values: [FeeOption: LoadingValue<Fee>]) {
        feeRowViewModels = values.map { option, fee in
            mapToFeeRowViewModel(option: option, fee: fee)
        }
    }

    private func mapToFeeRowViewModel(option: FeeOption, fee: LoadingValue<Fee>) -> FeeRowViewModel {
        let feeComponents = mapToFormattedFeeComponents(fee: fee)

        return FeeRowViewModel(
            option: option,
            formattedFeeComponents: feeComponents,
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == option
            }, set: { root, newValue in
                if newValue, let fee = fee.value {
                    root.userDidSelected(option: option, fee: fee)
                }
            })
        )
    }

    private func mapToFormattedFeeComponents(fee: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch fee {
        case .loading:
            return .loading
        case .loaded(let value):
            let feeComponents = feeFormatter.formattedFeeComponents(fee: value.amount.value, tokenItem: tokenItem)
            return .loaded(feeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }

    private func userDidSelected(option: FeeOption, fee: Fee) {
        if option == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

//        selectedFeeOption = feeOption
        output?.feeDidChanged(fee: fee)
//        showCustomFeeFields = feeOption == .custom
    }

//    private func onCustomFeeChanged(_ focused: Bool) {
//        if focused {
//            customFeeBeforeEditing = customFeeValue
//        } else {
//            if customFeeValue != customFeeBeforeEditing {
//                Analytics.log(.sendPriorityFeeInserted)
//            }
//
//            customFeeBeforeEditing = nil
//        }
//    }
}

extension SendFeeViewModel: AuxiliaryViewAnimatable {}

extension SendFeeViewModel {
    struct Initial {
        let tokenItem: TokenItem
        let feeOptions: [FeeOption]
    }
}

// MARK: - private extensions

private extension AnyPublisher where Output == Fee?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.amount.value }.eraseToAnyPublisher()
    }
}

private extension AnyPublisher where Output == BigUInt?, Failure == Never {
    var decimalPublisher: AnyPublisher<Decimal?, Never> {
        map { $0?.decimal }.eraseToAnyPublisher()
    }
}
