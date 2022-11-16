//
//  ReceiveCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReceiveCurrencyViewModel: Identifiable {
    var id: Int { hashValue }

    private(set) var state: State
    let tokenItem: TokenItem
    let didTapTokenView: () -> Void

    init(
        state: State,
        tokenItem: TokenItem,
        didTapTokenView: @escaping () -> Void
    ) {
        self.state = state
        self.tokenItem = tokenItem
        self.didTapTokenView = didTapTokenView
    }

    mutating func updateState(_ state: State) {
        self.state = state
    }
}

extension ReceiveCurrencyViewModel {
    enum State: Hashable {
        case loading
        case loaded(_ value: String, fiatValue: String)

        var value: String? {
            switch self {
            case .loaded(let value, _):
                return value
            default:
                return nil
            }
        }

        var fiatValue: String? {
            switch self {
            case .loaded(_, let fiatValue):
                return fiatValue
            default:
                return nil
            }
        }
    }
}


extension ReceiveCurrencyViewModel: Hashable {
    static func == (lhs: ReceiveCurrencyViewModel, rhs: ReceiveCurrencyViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
        hasher.combine(tokenItem)
    }
}

struct ReceiveCurrencyView: View {
    private let viewModel: ReceiveCurrencyViewModel

    init(viewModel: ReceiveCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerLabel

            mainContent
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }

    private var headerLabel: some View {
        Text("exchange_receive_view_header".localized)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: 0) {
            switch viewModel.state {
            case .loading:
                loadingContent
            case let .loaded(value, fiatValue):
                currencyContent(value: value, fiatValue: fiatValue)
            }

            Spacer()

            tokenView
        }
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            SkeletonView()
                .frame(width: 102, height: 21)
                .cornerRadius(6)

            SkeletonView()
                .frame(width: 40, height: 11)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }

    private func currencyContent(value: String, fiatValue: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)

            Text(fiatValue)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var tokenView: some View {
        Button(action: viewModel.didTapTokenView) {
            HStack(spacing: 8) {
                TokenIconView(tokenItem: viewModel.tokenItem)

                Assets.chevronDownMini
                    .resizable()
                    .frame(width: 9, height: 9)
            }
        }
    }
}

struct ReceiveCurrencyView_Preview: PreviewProvider {
    static let viewModel = ReceiveCurrencyViewModel(
        state: .loaded("1 131,46", fiatValue: "1 000,71 $"),
        tokenItem: .blockchain(.bitcoin(testnet: false))
    ) {}

    static let loadingViewModel = ReceiveCurrencyViewModel(
        state: .loading,
        tokenItem: .blockchain(.bitcoin(testnet: false))
    ) {}

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            VStack {
                ReceiveCurrencyView(viewModel: viewModel)

                ReceiveCurrencyView(viewModel: loadingViewModel)
            }
            .padding(.horizontal, 16)
        }
    }
}
