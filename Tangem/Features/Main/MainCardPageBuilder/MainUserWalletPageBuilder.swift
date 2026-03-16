//
//  MainUserWalletPageBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation

enum MainUserWalletPageBuilder: Identifiable {
    case singleWallet(
        id: UserWalletId,
        navigationModel: MainNavigationViewModel,
        headerModel: MainHeaderViewModel,
        bodyModel: SingleWalletMainContentViewModel?
    )
    case multiWallet(
        id: UserWalletId,
        navigationModel: MainNavigationViewModel,
        headerModel: MainHeaderViewModel,
        bodyModel: MultiWalletMainContentViewModel
    )
    case lockedWallet(
        id: UserWalletId,
        navigationModel: MainNavigationViewModel,
        headerModel: MainHeaderViewModel,
        bodyModel: LockedWalletMainContentViewModel
    )
    case visaWallet(
        id: UserWalletId,
        navigationModel: MainNavigationViewModel,
        headerModel: MainHeaderViewModel,
        bodyModel: VisaWalletMainContentViewModel
    )

    var id: UserWalletId {
        switch self {
        case .singleWallet(let id, _, _, _):
            return id
        case .multiWallet(let id, _, _, _):
            return id
        case .lockedWallet(let id, _, _, _):
            return id
        case .visaWallet(let id, _, _, _):
            return id
        }
    }

    var isLockedWallet: Bool {
        switch self {
        case .lockedWallet: return true
        case .singleWallet, .multiWallet, .visaWallet: return false
        }
    }

    private var footerViewModel: MainFooterViewModel? {
        switch self {
        case .singleWallet:
            return nil
        case .multiWallet(_, _, _, let bodyModel):
            return bodyModel.footerViewModel
        case .lockedWallet(_, _, _, let bodyModel):
            return bodyModel.footerViewModel
        case .visaWallet:
            return nil
        }
    }

    private var bottomSheetFooterViewModel: MainBottomSheetFooterViewModel? {
        switch self {
        case .singleWallet(_, _, _, let bodyModel):
            return bodyModel?.bottomSheetFooterViewModel
        case .multiWallet(_, _, _, let bodyModel):
            return bodyModel.bottomSheetFooterViewModel
        case .lockedWallet(_, _, _, let bodyModel):
            return bodyModel.bottomSheetFooterViewModel
        case .visaWallet:
            return nil
        }
    }

    private var headerModel: MainHeaderViewModel {
        switch self {
        case .singleWallet(_, _, let headerModel, _): headerModel
        case .multiWallet(_, _, let headerModel, _): headerModel
        case .lockedWallet(_, _, let headerModel, _): headerModel
        case .visaWallet(_, _, let headerModel, _): headerModel
        }
    }

    private var actionButtonsViewModel: ActionButtonsViewModel? {
        switch self {
        case .singleWallet(_, _, _, let bodyModel):
            return bodyModel?.actionButtonsViewModel
        case .multiWallet(_, _, _, let bodyModel):
            return bodyModel.actionButtonsViewModel
        case .lockedWallet(_, _, _, let bodyModel):
            return bodyModel.actionButtonsViewModel
        case .visaWallet:
            return nil
        }
    }

    private var navigationModel: MainNavigationViewModel {
        switch self {
        case .singleWallet(_, let navigationModel, _, _): navigationModel
        case .multiWallet(_, let navigationModel, _, _): navigationModel
        case .lockedWallet(_, let navigationModel, _, _): navigationModel
        case .visaWallet(_, let navigationModel, _, _): navigationModel
        }
    }

    var navigation: some View {
        MainNavigationView(viewModel: navigationModel)
    }

    var header: some View {
        MainHeaderView(viewModel: headerModel)
    }

    func redesignedHeader(totalPages: Int, currentIndex: Int) -> some View {
        MainUserWalletHeader(model: MainUserWalletHeaderModel(
            headerViewModel: headerModel,
            actionButtonsViewModel: actionButtonsViewModel,
            paginationState: totalPages > 1
                ? MainUserWalletHeaderModel.PaginationState(
                    totalPages: totalPages,
                    currentIndex: currentIndex
                )
                : nil
        ))
    }

    @ViewBuilder
    var body: some View {
        switch self {
        case .singleWallet(let id, _, _, let bodyModel):
            makeSingleWalletContent(id: id, bodyModel: bodyModel)

        case .multiWallet(let id, _, _, let bodyModel):
            makeMultiWalletContent(id: id, bodyModel: bodyModel)

        case .lockedWallet(let id, _, _, let bodyModel):
            makeLockedWalletContent(id: id, bodyModel: bodyModel)

        case .visaWallet(let id, _, _, let bodyModel):
            // Visa wallet redesign is not yet implemented
            VisaWalletMainContentView(viewModel: bodyModel)
                .id(id)
        }
    }

    @ViewBuilder
    private func makeSingleWalletContent(id: UserWalletId, bodyModel: SingleWalletMainContentViewModel?) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            if let bodyModel {
                SingleWalletMainContentRedesignedView(viewModel: bodyModel)
                    .id(id)
            } else {
                LoadingSingleWalletMainContentRedesignedView()
                    .id(id)
            }
        } else {
            if let bodyModel {
                SingleWalletMainContentView(viewModel: bodyModel)
                    .id(id)
            } else {
                LoadingSingleWalletMainContentView()
                    .id(id)
            }
        }
    }

    @ViewBuilder
    private func makeMultiWalletContent(id: UserWalletId, bodyModel: MultiWalletMainContentViewModel) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            MultiWalletMainContentRedesignedView(viewModel: bodyModel)
                .id(id)
        } else {
            MultiWalletMainContentView(viewModel: bodyModel)
                .id(id)
        }
    }

    @ViewBuilder
    private func makeLockedWalletContent(id: UserWalletId, bodyModel: LockedWalletMainContentViewModel) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            LockedWalletMainContentRedesignedView(viewModel: bodyModel)
                .id(id)
        } else {
            LockedWalletMainContentView(viewModel: bodyModel)
                .id(id)
        }
    }

    var missingBodyModel: Bool {
        switch self {
        case .singleWallet(_, _, _, let bodyModel):
            return bodyModel == nil
        case .multiWallet, .lockedWallet, .visaWallet:
            return false
        }
    }

    @ViewBuilder
    func makeBottomOverlay(_ overlayParams: CardsInfoPagerBottomOverlayFactoryParams) -> some View {
        if let viewModel = bottomSheetFooterViewModel {
            MainBottomSheetFooterView(viewModel: viewModel)
                .overlay {
                    MainBottomSheetHintView(
                        isDraggingHorizontally: overlayParams.isDraggingHorizontally,
                        didScrollToBottom: overlayParams.didScrollToBottom,
                        scrollOffset: overlayParams.scrollOffset,
                        viewportSize: overlayParams.viewportSize,
                        contentSize: overlayParams.contentSize,
                        scrollViewBottomContentInset: overlayParams.scrollViewBottomContentInset
                    )
                }
        } else if let viewModel = footerViewModel {
            MainFooterView(viewModel: viewModel, didScrollToBottom: overlayParams.didScrollToBottom)
        } else {
            EmptyMainFooterView()
        }
    }
}

// MARK: - MainViewPage protocol conformance

extension MainUserWalletPageBuilder: MainViewPage {
    func onPageAppear() {
        switch self {
        case .singleWallet(_, _, _, let bodyModel):
            bodyModel?.onPageAppear()
        case .multiWallet(_, _, _, let bodyModel):
            bodyModel.onPageAppear()
        case .lockedWallet, .visaWallet:
            break
        }
    }

    func onPageDisappear() {
        switch self {
        case .singleWallet(_, _, _, let bodyModel):
            bodyModel?.onPageDisappear()
        case .multiWallet(_, _, _, let bodyModel):
            bodyModel.onPageDisappear()
        case .lockedWallet, .visaWallet:
            break
        }
    }
}
