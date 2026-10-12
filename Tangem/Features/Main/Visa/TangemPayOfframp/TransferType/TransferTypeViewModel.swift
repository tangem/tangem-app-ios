//
//  TransferTypeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class TransferTypeViewModel: ObservableObject {
    @Published private(set) var selection: TransferTypeOption?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let analyticsLogger: any TangemPayOfframpAnalyticsLogger
    private let output: (Output) -> Void

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        title: String,
        stepSubtitle: String?,
        analyticsLogger: any TangemPayOfframpAnalyticsLogger,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.analyticsLogger = analyticsLogger
        self.output = output

        selection = orderBuilder.isThirdParty.map(TransferTypeOption.init(isThirdParty:))

        analyticsLogger.logPersonalAccountTypeScreenOpened()
    }

    var contentState: TransferTypeContentView.State {
        TransferTypeContentView.State(
            options: TransferTypeOption.allCases,
            selection: selection
        )
    }

    func handle(_ action: TransferTypeContentView.Action) {
        switch action {
        case .optionTap(let option):
            selection = option
        case .continueTap:
            submit()
        }
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Actions

private extension TransferTypeViewModel {
    func submit() {
        guard let selection else { return }

        orderBuilder.set(isThirdParty: selection.isThirdParty)

        analyticsLogger.logPersonalAccountTypeContinueClicked(isThirdParty: selection.isThirdParty)
        output(.continueWizard)
    }
}

// MARK: - Output

extension TransferTypeViewModel {
    enum Output {
        case continueWizard
        case close
    }
}
