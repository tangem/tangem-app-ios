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
import TangemLocalization
import TangemUI

final class FeedReferralWalletSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    struct Row: Identifiable {
        let item: WalletSelectorItemViewModel
        let isAvailable: Bool

        var id: UserWalletId { item.userWalletId }
    }

    @Published private(set) var rows: [Row]
    let close: () -> Void
    private var candidatesSubscription: AnyCancellable?

    init(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        onSelect: @escaping (UserWalletId) -> Void,
        close: @escaping () -> Void
    ) {
        self.close = close
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
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: Localization.commonChooseWallet,
                backAction: nil,
                closeAction: viewModel.close
            )
        ) {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.rows) { row in
                            WalletSelectorItemView(viewModel: row.item)
                                .buttonStyle(.plain)
                                .disabled(!row.isAvailable)
                                .opacity(row.isAvailable ? 1 : 0.5)
                                .saturation(row.isAvailable ? 1 : 0)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)

                TangemUI.Button(
                    label: AttributedString(Localization.commonCancel),
                    accessibilityLabel: Localization.commonCancel,
                    action: viewModel.close
                )
                .styleType(.secondary(.default))
                .size(.x12)
                .horizontalLayout(.infinity)
                .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            config.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
