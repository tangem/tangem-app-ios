//
//  MarketsMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import Kingfisher

final class MarketsMainViewModel: MarketsBaseViewModel {
    private typealias SearchInput = MainBottomSheetHeaderViewModel.SearchInput

    // MARK: - Injected & Published Properties

    @Published private(set) var headerViewModel: MainBottomSheetHeaderViewModel
    @Published private(set) var widgetItems: [WidgetItem] = []

    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.viewHierarchySnapshotter) private var viewHierarchySnapshotter: ViewHierarchySnapshotting

    // MARK: - Properties

    var isSearching: Bool {
        !currentSearchValue.isEmpty
    }

    override var overlayContentHidingProgress: CGFloat {
        // Prevents unwanted content hiding (see [REDACTED_INFO]
        isViewVisible ? super.overlayContentHidingProgress : 1.0
    }

    // [REDACTED_TODO_COMMENT]
    private lazy var widgetsProvider: MarketsWidgetsProvder = CommonMarketsWidgetDataService()

    private weak var coordinator: MarketsMainRoutable?

    private var bag = Set<AnyCancellable>()
    private var currentSearchValue: String = ""
    private var isViewVisible: Bool = false
    private var isBottomSheetExpanded: Bool = false

    // MARK: - Init

    init(coordinator: MarketsMainRoutable) {
        self.coordinator = coordinator

        headerViewModel = MainBottomSheetHeaderViewModel()

        // Our view is initially presented when the sheet is collapsed, hence the `0.0` initial value.
        super.init(overlayContentProgressInitialValue: 0.0)

        headerViewModel.delegate = self

        searchTextBind(publisher: headerViewModel.enteredSearchInputPublisher)
        bindToWidgets()

        widgetsProvider.initialize()
    }

    deinit {
        AppLogger.debug("MarketsMainViewModel deinit")
    }

    /// Handles `SwiftUI.View.onAppear(perform:)`.
    func onViewAppear() {
        isViewVisible = true
    }

    /// Handles `SwiftUI.View.onDisappear(perform:)`.
    func onViewDisappear() {
        isViewVisible = false
    }

    func onOverlayContentStateChange(_ state: OverlayContentState) {
        switch state {
        case .expanded:
            // Need for locked fetchMore process when bottom sheet not yet open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isBottomSheetExpanded = true
            }

            headerViewModel.onBottomSheetExpand(isTapGesture: state.isTapGesture)
        case .collapsed:
            isBottomSheetExpanded = false
        }
    }
}

// MARK: - Private Implementation

private extension MarketsMainViewModel {
    private func searchTextBind(publisher: some Publisher<SearchInput, Never>) {
        publisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            // Ensure that clear input event will be delivered immediately
            .merge(with: publisher.filter { $0 == .clearInput })
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchInput in
                // [REDACTED_TODO_COMMENT]
            }
            .store(in: &bag)
    }

    func bindToWidgets() {
        widgetsProvider
            .widgetsPublisher
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, widgets in
                viewModel.widgetItems = widgets
                    .filter(\.isEnabled)
                    .sorted(by: \.order)
                    .compactMap {
                        switch $0.type {
                        case .banner:
                            return .banner(widgetModel: $0)
                        case .news:
                            return .news("")
                        default:
                            return nil
                        }
                    }
            }
            .store(in: &bag)
    }

    func bindToMainBottomSheetUIManager() {
        mainBottomSheetUIManager
            .footerSnapshotUpdateTriggerPublisher
            .sink(receiveValue: weakify(self, forFunction: MarketsMainViewModel.updateFooterSnapshot))
            .store(in: &bag)
    }

    func updateFooterSnapshot() {
        let lightAppearanceSnapshotImage = viewHierarchySnapshotter.makeSnapshotViewImage(
            afterScreenUpdates: true,
            isOpaque: true,
            overrideUserInterfaceStyle: .light
        )
        let darkAppearanceSnapshotImage = viewHierarchySnapshotter.makeSnapshotViewImage(
            afterScreenUpdates: true,
            isOpaque: true,
            overrideUserInterfaceStyle: .dark
        )

        mainBottomSheetUIManager.setFooterSnapshots(
            lightAppearanceSnapshotImage: lightAppearanceSnapshotImage,
            darkAppearanceSnapshotImage: darkAppearanceSnapshotImage
        )
    }
}

extension MarketsMainViewModel: MainBottomSheetHeaderViewModelDelegate {
    func isViewVisibleForHeaderViewModel(_ viewModel: MainBottomSheetHeaderViewModel) -> Bool {
        return isViewVisible
    }
}

extension MarketsMainViewModel {
    enum WidgetItem: Identifiable, Hashable, Equatable {
        var id: String {
            switch self {
            case .banner(let widgetModel), .news(let widgetModel):
                return widgetModel.id
            }
        }
        
        case banner(widgetModel: MarketsWidgetModel)
        case news(widgetModel: MarketsWidgetModel)
    }
}
