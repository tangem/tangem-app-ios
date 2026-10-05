//
//  FeedReferralWalletSelector.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets
import TangemFoundation
import TangemUI
import TangemUIUtils

final class FeedReferralWalletSelectorViewModel: ObservableObject {
    struct Row: Identifiable {
        let item: WalletSelectorItemViewModel
        let isAvailable: Bool

        var id: UserWalletId { item.userWalletId }
    }

    @Published private(set) var rows: [Row]
    private var candidatesSubscription: AnyCancellable?

    init(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        onSelect: @escaping (UserWalletId) -> Void
    ) {
        rows = Self.makeRows(candidates: candidates, onSelect: onSelect)

        candidatesSubscription = candidatesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, candidates in
                viewModel.rows = Self.makeRows(candidates: candidates, onSelect: onSelect)
            }
    }

    private static func makeRows(candidates: [FeedReferralWalletCandidate], onSelect: @escaping (UserWalletId) -> Void) -> [Row] {
        candidates.map { candidate in
            let wallet = candidate.wallet
            let item = WalletSelectorItemViewModel(
                userWalletId: wallet.userWalletId,
                cardSetLabel: wallet.cardSetLabel,
                isUserWalletLocked: wallet.isUserWalletLocked,
                infoProvider: wallet,
                totalBalancePublisher: wallet.totalBalancePublisher,
                isSelected: false
            ) { _ in
                onSelect(wallet.userWalletId)
            }

            return Row(item: item, isAvailable: candidate.isAvailable)
        }
    }
}

struct FeedReferralWalletSelectorView: View {
    @ObservedObject var viewModel: FeedReferralWalletSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.rows) { row in
                WalletSelectorItemView(viewModel: row.item)
                    .buttonStyle(.plain)
                    .padding(.horizontal, Constants.cellHorizontalPadding)
                    .disabled(!row.isAvailable)
                    .opacity(row.isAvailable ? 1 : 0.5)
                    .saturation(row.isAvailable ? 1 : 0)
            }
        }
        .background(DesignSystem.Color.bgTransparentOnMaterialPrimary)
        .cornerRadiusContinuous(Constants.cornerRadius)
        .padding(Constants.padding)
    }
}

// MARK: - Constants

private extension FeedReferralWalletSelectorView {
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 20
        static let cellHorizontalPadding: CGFloat = 14
    }
}
