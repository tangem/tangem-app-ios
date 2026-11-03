//
//  JointAccountConfirmSharedAddressView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountConfirmSharedAddressView: View {
    @ObservedObject var viewModel: JointAccountConfirmSharedAddressViewModel

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            GroupedScrollView(contentType: .plain(alignment: .leading, spacing: 0)) {
                content
            }
            .footer { Footer(.signingButton(confirmButton, secondary: mismatchButton)).showFade() }
        }
        .topNavigation(leading: .automatic)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            JointAccountHeaderTitle(
                title: Localization.jointAccountConfirmSharedAddress,
                subtitle: Localization.jointAccountConfirmAccountSubtitle
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 4)

            addressCard
                .padding(.vertical, 8)

            points
                .padding(.vertical, 16)
        }
    }

    private var addressCard: some View {
        HStack(spacing: 0) {
            Row(title: viewModel.address, subtitle: Localization.jointAccountConfirmAddressLabel)
                .lineOrder(.secondaryFirst)
                .titleLineLimit(nil)
                .onTap(action: viewModel.onAddressTap)
                .accessibilityHint(Localization.commonCopy)

            shareAddressButton
                .padding(.trailing, 16)
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var shareAddressButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.ShareIos.regular20,
            accessibilityLabel: Localization.commonShare,
            action: viewModel.onShareAddressTap
        )
        .styleType(.secondary(.default))
        .size(.x9)
    }

    private var points: some View {
        VStack(spacing: 0) {
            ForEach(Point.allCases, id: \.self) { point in
                pointRow(point)
            }
        }
    }

    private func pointRow(_ point: Point) -> some View {
        Row(title: point.title, subtitle: point.subtitle)
            .subtitleLineLimit(nil)
            .verticalAlignment(.top)
            .includeInnerPadding(false)
            .start {
                point.icon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
    }

    private var mismatchButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.jointAccountConfirmAddressMismatchButton,
            accessibilityLabel: Localization.jointAccountConfirmAddressMismatchButton,
            action: viewModel.onAddressMismatchTap
        )
        .styleType(.secondary(.default))
    }

    private var confirmButton: SigningActionButtonView {
        SigningActionButtonView(
            type: viewModel.signingActionButtonType,
            title: Localization.jointAccountConfirmAddressConfirmButton,
            isLoading: viewModel.isConfirming,
            isDisabled: false,
            action: viewModel.onConfirmTap
        )
    }
}

// MARK: - Point

private extension JointAccountConfirmSharedAddressView {
    enum Point: CaseIterable {
        case compare
        case everyoneConfirms

        var icon: ImageType {
            switch self {
            case .compare: DesignSystem.Icons.Users.regular20
            case .everyoneConfirms: DesignSystem.Icons.Success.regular20
            }
        }

        var title: String {
            switch self {
            case .compare: Localization.jointAccountConfirmAddressCompareTitle
            case .everyoneConfirms: Localization.jointAccountConfirmAddressEveryoneTitle
            }
        }

        var subtitle: String {
            switch self {
            case .compare: Localization.jointAccountConfirmAddressCompareSubtitle
            case .everyoneConfirms: Localization.jointAccountConfirmAddressEveryoneSubtitle
            }
        }
    }
}

// MARK: - Previews

/// Outlives the account of the preview below, which holds it weakly.
private let previewJointAccountDelegate = JointAccountModelDelegateMock()

#Preview {
    let jointAccount = CommonJointAccountModel(
        cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
        derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
        accountPolicy: JointAccountPolicy(membersCount: 3, signersCount: 2),
        accountStatus: .confirming(safeAddress: "0xbef7b368aac4e6752a9ce0xbef7b36a9cevef7b2336"),
        operationsService: JointAccountOperationsServiceMock(),
        pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
        membersService: JointAccountMembersServiceMock(),
        finishedOperationsWalletUpdater: JointAccountFinishedOperationsWalletUpdater(
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            walletModelsManager: WalletModelsManagerMock(),
            historyDeltaSyncing: MockJointOperationsHistorySyncService()
        ),
        userRoleService: JointAccountUserRoleServiceMock(),
        delegate: previewJointAccountDelegate
    )

    NavigationStack {
        JointAccountConfirmSharedAddressView(
            viewModel: JointAccountConfirmSharedAddressViewModel(
                address: "0xbef7b368aac4e6752a9ce0xbef7b36a9cevef7b2336",
                jointAccount: jointAccount,
                signingActionButtonType: .requiredNFCInteraction,
                coordinator: nil
            )
        )
    }
}
