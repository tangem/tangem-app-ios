//
//  AccountTypeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class AccountTypeViewModel: ObservableObject {
    @Published private(set) var selection: AccountTypeOption?

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let output: (Output) -> Void

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        title: String,
        stepSubtitle: String?,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.output = output

        selection = orderBuilder.accountType.map(AccountTypeOption.init(bankAccountType:))
    }

    var contentState: AccountTypeContentView.State {
        AccountTypeContentView.State(
            options: AccountTypeOption.allCases,
            selection: selection
        )
    }

    func handle(_ action: AccountTypeContentView.Action) {
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

private extension AccountTypeViewModel {
    func submit() {
        guard let selected = selection?.bankAccountType else {
            return
        }

        orderBuilder.set(accountType: selected)
        output(.continueWizard)
    }
}

// MARK: - Output

extension AccountTypeViewModel {
    enum Output {
        case continueWizard
        case close
    }
}
