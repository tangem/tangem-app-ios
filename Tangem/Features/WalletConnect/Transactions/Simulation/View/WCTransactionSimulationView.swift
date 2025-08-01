//
//  WCTransactionSimulationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemLocalization
import TangemUI

struct WCTransactionSimulationView: View {
    @State private var connectionRequestIconIsRotating = false

    private let displayModel: WCTransactionSimulationDisplayModel?

    init(displayModel: WCTransactionSimulationDisplayModel?) {
        self.displayModel = displayModel
    }

    var body: some View {
        if let displayModel {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayModel.cardTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    switch displayModel.content {
                    case .loading:
                        loadingRow
                            .transition(.opacity.animation(.curve(.easeInOutRefined, duration: 0.3)))
                    case .failed(let message):
                        failedView(message: message)
                            .transition(topEdgeTransition)
                    case .success(let successContent):
                        content(for: successContent)
                            .transition(topEdgeTransition)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 14))
                .background(Colors.Background.action)
                .cornerRadius(14)
            }
            .onAppear {
                connectionRequestIconIsRotating = true
            }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 8) {
            Assets.Glyphs.load.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: 20))
                .foregroundStyle(Colors.Icon.accent)
                .rotationEffect(.degrees(connectionRequestIconIsRotating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: connectionRequestIconIsRotating)
            Text(Localization.wcCommonLoading)
                .style(Fonts.Regular.body, color: Colors.Text.disabled)
        }
    }

    private func failedView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
        }
    }

    private func content(for successContent: WCTransactionSimulationDisplayModel.SuccessContent) -> some View {
        ForEach(Array(successContent.sections.enumerated()), id: \.offset) { index, section in
            switch section {
            case .assetChanges(let assetChanges):
                assetChangesSection(assetChanges)
            case .approvals(let approvals):
                approvalsSection(approvals)
            case .noChanges:
                noChangesView()
            }
        }
    }

    private func assetChangesSection(_ assetChanges: WCTransactionSimulationDisplayModel.AssetChangesSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !assetChanges.sendItems.isEmpty {
                ForEach(Array(assetChanges.sendItems.enumerated()), id: \.offset) { index, item in
                    assetItemRow(item)

                    if assetChanges.sendItems.last != item {
                        Separator(height: .minimal, color: Colors.Stroke.primary, axis: .horizontal)
                            .padding(.leading, 32)
                    }
                }
            }

            if !assetChanges.sendItems.isEmpty, !assetChanges.receiveItems.isEmpty {
                Separator(height: .minimal, color: Colors.Stroke.primary, axis: .horizontal)
                    .padding(.leading, 32)
            }

            if !assetChanges.receiveItems.isEmpty {
                ForEach(Array(assetChanges.receiveItems.enumerated()), id: \.offset) { index, item in
                    assetItemRow(item)

                    if assetChanges.receiveItems.last != item {
                        Separator(height: .minimal, color: Colors.Stroke.primary, axis: .horizontal)
                            .padding(.leading, 32)
                    }
                }
            }
        }
    }

    private func approvalsSection(_ approvals: WCTransactionSimulationDisplayModel.ApprovalsSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(approvals.items.enumerated()), id: \.offset) { index, item in
                approvalItemRow(item)
            }
        }
        .frame(alignment: .topLeading)
    }

    @ViewBuilder
    private func directionImage(for direction: WCTransactionSimulationDisplayModel.AssetItem.Direction) -> some View {
        switch direction {
        case .receive:
            Assets.Glyphs.recieveNew.image.foregroundStyle(Colors.Icon.accent)
        case .send:
            Assets.Glyphs.sendNew.image.foregroundStyle(Colors.Icon.warning)
        }
    }

    private func directionTitle(for direction: WCTransactionSimulationDisplayModel.AssetItem.Direction) -> String {
        switch direction {
        case .receive:
            return Localization.commonReceive
        case .send:
            return Localization.commonSend
        }
    }

    private func directionSign(for direction: WCTransactionSimulationDisplayModel.AssetItem.Direction) -> String {
        switch direction {
        case .receive:
            return "+"
        case .send:
            return "–"
        }
    }

    private func assetItemRow(_ item: WCTransactionSimulationDisplayModel.AssetItem) -> some View {
        HStack(spacing: 8) {
            directionImage(for: item.direction)

            Text(directionTitle(for: item.direction))
                .style(Fonts.Regular.body, color: Colors.Text.primary1)

            Spacer()

            Text("\(directionSign(for: item.direction))\(item.formattedAmount) \(item.symbol)")
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func approvalItemRow(_ item: WCTransactionSimulationDisplayModel.ApprovalItem) -> some View {
        HStack(spacing: 8) {
            leftContentView(for: item.leftContent)

            Spacer()

            rightContentView(for: item.rightContent)

            if item.isEditable, let onEdit = item.onEdit {
                editButton(onEdit: onEdit)
            }
        }
    }

    private func leftContentView(for content: WCTransactionSimulationDisplayModel.ApprovalItem.LeftContent) -> some View {
        HStack(spacing: 8) {
            switch content {
            case .editable(let iconURL, let formattedAmount, let asset):
                Text(formattedAmount)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            case .nonEditable:
                Assets.Glyphs.approvaleNew.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 24))
                    .foregroundStyle(Colors.Icon.accent)

                Text(Localization.commonApprove)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            }
        }
    }

    private func rightContentView(for content: WCTransactionSimulationDisplayModel.ApprovalItem.RightContent) -> some View {
        HStack(spacing: 8) {
            switch content {
            case .tokenInfo(let formattedAmount, let iconURL, let asset):
                Text(formattedAmount)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            case .empty:
                EmptyView()
            }
        }
    }

    private func editButton(onEdit: @escaping () -> Void) -> some View {
        Button(
            action: onEdit,
            label: {
                HStack(spacing: 4) {
                    Text(Localization.commonEdit)
                        .style(Fonts.Regular.body, color: Colors.Text.tertiary)

                    Assets.Glyphs.editNew.image
                        .foregroundStyle(Colors.Icon.informative)
                }
            }
        )
        .buttonStyle(.plain)
    }

    private func noChangesView() -> some View {
        Text("No wallet changes detected")
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
    }

    var topEdgeTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: mainContentOpacityTransitionWithDelay),
            removal: .move(edge: .top).combined(with: mainContentOpacityTransition)
        )
    }

    var mainContentOpacityTransition: AnyTransition {
        .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    }

    var mainContentOpacityTransitionWithDelay: AnyTransition {
        .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2))
    }
}
