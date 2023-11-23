//
//  ExpressSuccessSentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

// [REDACTED_TODO_COMMENT]
// [REDACTED_INFO]
final class ExpressSuccessSentViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var sourceData: AmountSummaryViewData?
    @Published var destinationData: AmountSummaryViewData?
    @Published var provider: ProviderRowViewModel?
    @Published var expressFee: ExpressFeeRowData?

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        return formatter.string(from: Date())
    }

    // MARK: - Dependencies

    private unowned let coordinator: ExpressSuccessSentRoutable

    init(
        input: InputModel,
        coordinator: ExpressSuccessSentRoutable
    ) {
        self.coordinator = coordinator
        setupView()
    }

    func openExplore() {}

    func openShare() {}

    func closeView() {}
}

private extension ExpressSuccessSentViewModel {
    func setupView() {
        sourceData = AmountSummaryViewData(
            amount: "1 000 DAI",
            amountFiat: "568,65 $",
            tokenIconName: "dai",
            tokenIconURL: TokenIconURLBuilder().iconURL(id: "dai"),
            tokenIconCustomTokenColor: nil,
            tokenIconBlockchainIconName: "ethereum",
            isCustomToken: false
        )

        destinationData = AmountSummaryViewData(
            amount: "1 000 DAI",
            amountFiat: "568,65 $",
            tokenIconName: "dai",
            tokenIconURL: TokenIconURLBuilder().iconURL(id: "dai"),
            tokenIconCustomTokenColor: nil,
            tokenIconBlockchainIconName: "ethereum",
            isCustomToken: false
        )

        provider = ProviderRowViewModel(
            provider: .init(
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/changenow_512.png")!,
                name: "ChangeNOW",
                type: "CEX"
            ),
            isDisabled: false,
            badge: .none,
            subtitles: [.text("0,64554846 DAI ≈ 1 MATIC ")],
            detailsType: .none,
            // Should be replaced on id
            tapAction: {}
        )

        expressFee = ExpressFeeRowData(title: "Fee", subtitle: "0.117 MATIC (0.14 $)", action: nil)
    }
}

extension ExpressSuccessSentViewModel {
    struct InputModel {}
}
