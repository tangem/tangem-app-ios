//
//  PolymarketActivityViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

@MainActor
final class PolymarketActivityViewModel: ObservableObject, Identifiable {
    @Published private(set) var sections: [PolymarketActivitySection] = []
    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var isExporting = false

    @Published var tab: PolymarketActivityTab {
        didSet {
            guard tab != oldValue else { return }

            reload()
        }
    }

    @Published private(set) var canExport = false

    let tabs = PolymarketActivityTab.allCases

    var emptyMessage: String { tab.emptyMessage }

    var offersExploring: Bool { tab.offersExploring }

    var showsTabs: Bool { !(loadingState == .noResults && tab.offersExploring) }

    var loadedCount: Int { records.count }

    private var allowsAutomaticReload: Bool {
        guard case .error(let failure) = loadingState else { return true }

        return failure.isRetriedAutomatically
    }

    private let activityService: PolymarketActivityService
    private weak var coordinator: PolymarketActivityRoutable?

    private var records: [PolymarketActivityRecord] = []
    private var recordsTab: PolymarketActivityTab?
    private var seenIDs: Set<String> = []
    private var cursor: String?
    private var hasNext = false
    private var isRefreshingFirstPage = false
    private var isLoadMorePending = false
    private var nextScanAllowedAt: Date?
    private var loadingTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?
    private var skeletonTask: Task<Void, Never>?
    private var exportTask: Task<Void, Never>?

    init(
        tab: PolymarketActivityTab = .all,
        activityService: PolymarketActivityService,
        coordinator: PolymarketActivityRoutable?
    ) {
        self.tab = tab
        self.activityService = activityService
        self.coordinator = coordinator

        reload()
        scanForDeposits()
    }

    deinit {
        loadingTask?.cancel()
        skeletonTask?.cancel()
        scanTask?.cancel()
        exportTask?.cancel()
    }

    func refresh() async {
        scanForDeposits()
        refreshFirstPage()

        await loadingTask?.value
    }
}

// MARK: - View actions

extension PolymarketActivityViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .closeTapped:
            loadingTask?.cancel()
            exportTask?.cancel()
            coordinator?.closeActivity()
        case .retry:
            reload()
        case .loadNextPage, .retryNextPage:
            loadMore()
        case .exploreTapped:
            coordinator?.closeActivity()
        case .downloadCSVTapped:
            exportCSV()
        }
    }

    enum ViewAction {
        case closeTapped
        case retry
        case loadNextPage
        case retryNextPage
        case exploreTapped
        case downloadCSVTapped
    }
}

// MARK: - Loading

private extension PolymarketActivityViewModel {
    func reload() {
        loadingTask?.cancel()
        skeletonTask?.cancel()
        cursor = nil
        hasNext = false
        isRefreshingFirstPage = false
        isLoadMorePending = false

        if records.isEmpty {
            showSkeleton()
        } else {
            skeletonTask = runTask(in: self) { @MainActor viewModel in
                try? await Task.sleep(for: Constants.skeletonDelay)

                guard !Task.isCancelled else { return }

                viewModel.showSkeleton()
            }
        }

        fetch(cursor: nil, replacingRecords: true)
    }

    func showSkeleton() {
        records = []
        recordsTab = nil
        seenIDs = []
        sections = []
        loadingState = .loading
    }

    func refreshFirstPage() {
        guard !records.isEmpty, recordsTab == tab else {
            reload()
            return
        }

        loadingTask?.cancel()
        isRefreshingFirstPage = true
        fetch(cursor: nil, replacingRecords: true)
    }

    func loadMore() {
        guard !isRefreshingFirstPage else {
            isLoadMorePending = true
            return
        }

        guard hasNext, loadingState == .loaded || loadingState == .paginationError else { return }

        loadingState = .paginationLoading
        fetch(cursor: cursor, replacingRecords: false)
    }

    func fetch(cursor: String?, replacingRecords: Bool) {
        let tab = tab

        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let page = try await viewModel.activityService.activity(
                    filter: tab.filter,
                    limit: Constants.pageSize,
                    cursor: cursor
                )
                try Task.checkCancellation()

                guard tab == viewModel.tab else { return }

                if replacingRecords {
                    viewModel.records = []
                    viewModel.recordsTab = tab
                    viewModel.seenIDs = []
                }

                viewModel.append(page)
                viewModel.settle()
            } catch {
                guard !error.isCancellationError, !Task.isCancelled, tab == viewModel.tab else { return }

                PolymarketActivityFailure.log(error, while: "load the activity list")
                viewModel.settleAfterFailure(PolymarketActivityFailure(error: error), replacingRecords: replacingRecords)
            }
        }
    }

    func append(_ page: PolymarketActivityPage) {
        let fresh = page.records.filter { seenIDs.insert($0.id).inserted }

        records.append(contentsOf: fresh)
        cursor = page.nextCursor
        hasNext = page.nextCursor != nil

        rebuildSections()
    }

    func rebuildSections() {
        sections = PolymarketActivitySection.make(records: PolymarketActivityClaimGrouping.group(records))
    }

    func settle() {
        skeletonTask?.cancel()
        isRefreshingFirstPage = false
        canExport = !records.isEmpty

        if hasNext {
            loadingState = .loaded
        } else {
            loadingState = records.isEmpty ? .noResults : .allDataLoaded
        }

        if isLoadMorePending {
            isLoadMorePending = false
            loadMore()
        }
    }

    func settleAfterFailure(_ failure: PolymarketActivityFailure, replacingRecords: Bool) {
        skeletonTask?.cancel()

        if replacingRecords, !isRefreshingFirstPage {
            showSkeleton()
        }

        isRefreshingFirstPage = false

        switch (records.isEmpty, replacingRecords) {
        case (true, _):
            canExport = false
            loadingState = .error(failure)
        case (false, true): settle()
        case (false, false): loadingState = .paginationError
        }
    }
}

// MARK: - Export

private extension PolymarketActivityViewModel {
    func exportCSV() {
        guard !isExporting else { return }

        isExporting = true
        let filter = tab.filter
        let activityService = activityService

        exportTask = Task { @MainActor [weak self] in
            do {
                let records = try await Self.allRecords(filter: filter, activityService: activityService)
                let url = try PolymarketActivityCSV.write(records: records)

                guard let self, !Task.isCancelled else { return }

                isExporting = false
                coordinator?.shareActivityExport(url: url)
            } catch {
                self?.isExporting = false

                guard let self, !error.isCancellationError, !Task.isCancelled else { return }

                PolymarketActivityFailure.log(error, while: "export the activity list")
                presentExportFailureToast()
            }
        }
    }

    func presentExportFailureToast() {
        Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    static func allRecords(
        filter: PolymarketActivityFilter,
        activityService: PolymarketActivityService
    ) async throws -> [PolymarketActivityRecord] {
        var records: [PolymarketActivityRecord] = []
        var seenIDs: Set<String> = []
        var cursor: String?

        repeat {
            let page = try await activityService.activity(filter: filter, limit: Constants.exportPageSize, cursor: cursor)
            try Task.checkCancellation()

            records.append(contentsOf: page.records.filter { seenIDs.insert($0.id).inserted })
            cursor = page.nextCursor
        } while cursor != nil

        return records
    }
}

// MARK: - Looking for deposits

private extension PolymarketActivityViewModel {
    func scanForDeposits() {
        guard nextScanAllowedAt.map({ $0 <= Date() }) ?? true else { return }

        scanTask?.cancel()

        let activityService = activityService

        scanTask = Task { @MainActor [weak self] in
            guard let scan = await activityService.reconcileDeposits() else { return }

            self?.nextScanAllowedAt = Date().addingTimeInterval(scan.retryAfter)

            try? await Task.sleep(for: .seconds(scan.retryAfter))

            guard !Task.isCancelled, let self, records.count <= Constants.pageSize, allowsAutomaticReload else { return }

            refreshFirstPage()
        }
    }
}

// MARK: - State

extension PolymarketActivityViewModel {
    enum LoadingState: Equatable {
        case loading
        case noResults
        case error(PolymarketActivityFailure)
        case loaded
        case allDataLoaded
        case paginationLoading
        case paginationError
    }
}

// MARK: - Constants

private extension PolymarketActivityViewModel {
    enum Constants {
        static let pageSize = 25
        static let toastTopPadding: CGFloat = 16
        static let skeletonDelay: Duration = .milliseconds(300)
        static let exportPageSize = PolymarketActivityRequest.Constants.maxLimit
    }
}
