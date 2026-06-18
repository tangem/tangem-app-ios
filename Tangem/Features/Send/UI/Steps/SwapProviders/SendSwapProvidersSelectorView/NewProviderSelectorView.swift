//
//  NewProviderSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

struct NewProviderSelectorView: View {
    @ObservedObject var viewModel: SendSwapProvidersSelectorViewModel
    @State private var allModeSectionHeight: CGFloat = .zero

    private var approveDescriptionText: AttributedString {
        var learnMore = AttributedString(Localization.commonLearnMore)
        learnMore.font = Fonts.Regular.footnote

        if let range = learnMore.range(of: Localization.commonLearnMore) {
            learnMore[range].foregroundColor = Colors.Text.accent
            learnMore[range].link = URL(string: " ")
        }

        var subtitle = AttributedString(Localization.givePermissionSwapSubtitleV2(""))
        subtitle.font = Fonts.Regular.footnote
        subtitle.foregroundColor = Colors.Text.tertiary

        return subtitle + "\n" + learnMore
    }

    var body: some View {
        FeeSelectorBottomSheetContainerView(
            state: viewModel.viewState,
            showsButton: viewModel.viewState.showsButton,
            verticalSwipeBehavior: .init(target: .sheet, threshold: 100),
            button: { confirmButton },
            headerContent: { headerView },
            descriptionContent: { descriptionView },
            mainContent: { mainContentView }
        )
        .onDisappear {
            viewModel.resetState()
            allModeSectionHeight = .zero
        }
    }

    // MARK: - Header

    private var headerView: some View {
        BottomSheetHeaderView(
            title: viewModel.viewState.title,
            leading: { leadingHeaderButton },
            trailing: { NavigationBarButton.close(action: viewModel.dismiss) }
        )
    }

    @ViewBuilder
    private var leadingHeaderButton: some View {
        if case .approve = viewModel.viewState {
            NavigationBarButton.back(action: viewModel.closeApprove)
        }
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionView: some View {
        switch viewModel.viewState {
        case .providerList:
            if !viewModel.providerTypeFilterOptions.isEmpty {
                TangemSegmentedPicker(
                    data: viewModel.providerTypeFilterOptions,
                    selection: $viewModel.selectedProviderTypeFilter
                )
                .style(.flexible)
                .padding(.top, 8)
            }
        case .approve:
            approveStateDescriptionView
        }
    }

    private var approveStateDescriptionView: some View {
        Text(approveDescriptionText)
            .environment(\.openURL, OpenURLAction { _ in
                viewModel.openLearnMoreAboutApprove()
                return .handled
            })
            .multilineTextAlignment(.center)
    }

    // MARK: - Button

    @ViewBuilder
    private var confirmButton: some View {
        if case .approve = viewModel.viewState {
            MainButton(title: Localization.commonConfirm, action: viewModel.didTapConfirm)
        }
    }

    // MARK: - Main content

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.viewState {
        case .providerList:
            providerListContent
        case .approve(let menuViewModel):
            approveContent(menuViewModel: menuViewModel)
        }
    }

    private var providerListContent: some View {
        VStack(spacing: .zero) {
            if let ukNotificationInput = viewModel.ukNotificationInput {
                NotificationView(input: ukNotificationInput)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }

            SelectableSection(viewModel.providerViewModels) { data in
                SendSwapProvidersSelectorProviderView(data: data, isSelected: viewModel.isSelected(data.id).asBinding)
            } accessory: { data in
                if data.showTrailingSettingsButton {
                    approveSettingsButton(name: data.title)
                }
            }
            .enableSeparators(false)
            .padding(.horizontal, 14)
            .fixedSize(horizontal: false, vertical: true)
            .readGeometry(\.size.height) { height in
                if viewModel.selectedProviderTypeFilter == .all, height > allModeSectionHeight {
                    allModeSectionHeight = height
                }
            }
            .frame(minHeight: allModeSectionHeight, alignment: .top)

            ExpressMoreProvidersSoonView()
                .padding(.top, 18)
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
        }
    }

    private func approveSettingsButton(name: String) -> some View {
        Button(action: viewModel.openApprove) {
            Assets.sliders.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .padding(.horizontal, 20)
                .frame(maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Colors.Background.action))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(SendAccessibilityIdentifiers.swapProviderSelectorApproveButton(name: name))
    }

    private func approveContent(menuViewModel: DefaultMenuRowViewModel<BSDKApprovePolicy>) -> some View {
        GroupedSection(menuViewModel) {
            DefaultMenuRowView(viewModel: $0, selection: $viewModel.selectedApprovePolicy, titleFont: Fonts.Regular.body)
        }
        .backgroundColor(Colors.Background.action)
        .padding(.horizontal, 16)
    }
}
