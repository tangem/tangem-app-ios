//
//  MainHorizontalPagingScrollView+Backport.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI

extension MainHorizontalPagingScrollView {
    @available(iOS, obsoleted: 17.0, message: "Use native SwiftUI implementation.")
    struct HorizontalPagingScrollViewBackport: UIViewControllerRepresentable {
        final class Coordinator {
            var userWalletPageBuilders: [MainUserWalletPageBuilder]
            var selectedCardIndex: Int
            var containerGeometryProperties: UserWalletView.ContainerGeometryProperties
            var isHorizontalScrollDisabled: Bool
            var refreshingUserWalletIDs: Set<UserWalletId>

            init(
                userWalletPageBuilders: [MainUserWalletPageBuilder],
                selectedCardIndex: Int,
                containerGeometryProperties: UserWalletView.ContainerGeometryProperties,
                isHorizontalScrollDisabled: Bool,
                refreshingUserWalletIDs: Set<UserWalletId>
            ) {
                self.userWalletPageBuilders = userWalletPageBuilders
                self.selectedCardIndex = selectedCardIndex
                self.containerGeometryProperties = containerGeometryProperties
                self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
                self.refreshingUserWalletIDs = refreshingUserWalletIDs
            }
        }

        let userWalletPageBuilders: [MainUserWalletPageBuilder]

        let selectedCardIndex: Binding<Int>
        let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

        let containerGeometryProperties: UserWalletView.ContainerGeometryProperties

        let pullToRefreshAction: @MainActor (UserWalletId) -> Void
        let refreshingUserWalletIDs: Set<UserWalletId>
        let isHorizontalScrollDisabled: Bool
        let onContentPropertiesChanged: (UserWalletId, UserWalletView.ScrollContentProperties) -> Void
        let onPagingIndicatorOffsetChanged: (UserWalletId, UserWalletView.PagingIndicatorOffset) -> Void
        let onPagePositionChanged: (CGFloat) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex.wrappedValue,
                containerGeometryProperties: containerGeometryProperties,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                refreshingUserWalletIDs: refreshingUserWalletIDs
            )
        }

        func makeUIViewController(context: Context) -> HorizontalPagingCollectionViewController {
            HorizontalPagingCollectionViewController(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                onSelectedCardChanged: onSelectedCardChanged,
                containerGeometryProperties: containerGeometryProperties,
                pullToRefreshAction: pullToRefreshAction,
                refreshingUserWalletIDs: refreshingUserWalletIDs,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentPropertiesChanged: onContentPropertiesChanged,
                onPagingIndicatorOffsetChanged: onPagingIndicatorOffsetChanged,
                onPagePositionChanged: onPagePositionChanged
            )
        }

        func updateUIViewController(_ uiViewController: HorizontalPagingCollectionViewController, context: Context) {
            context.coordinator.userWalletPageBuilders = userWalletPageBuilders
            context.coordinator.selectedCardIndex = selectedCardIndex.wrappedValue
            context.coordinator.containerGeometryProperties = containerGeometryProperties
            context.coordinator.isHorizontalScrollDisabled = isHorizontalScrollDisabled
            context.coordinator.refreshingUserWalletIDs = refreshingUserWalletIDs

            uiViewController.update(by: context.coordinator)
        }
    }
}

@available(iOS, obsoleted: 17.0, message: "Use native SwiftUI implementation.")
final class HorizontalPagingCollectionViewController: UIViewController {
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, MainUserWalletPageBuilder>
    private typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>

    private lazy var layout: UICollectionViewFlowLayout = Self.makeFlowLayout()
    private lazy var collectionView: UICollectionView = Self.makeCollectionView(with: layout)
    private lazy var dataSource: DataSource = makeDataSource(for: collectionView)

    private var didPerformInitialScroll = false
    private var currentCollectionViewIndex: Int

    private(set) var userWalletPageBuilders: [MainUserWalletPageBuilder]

    let selectedCardIndex: Binding<Int>
    let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

    let pullToRefreshAction: @MainActor (UserWalletId) -> Void
    let onContentPropertiesChanged: (UserWalletId, UserWalletView.ScrollContentProperties) -> Void
    let onPagingIndicatorOffsetChanged: (UserWalletId, UserWalletView.PagingIndicatorOffset) -> Void
    let onPagePositionChanged: (CGFloat) -> Void

    private(set) var containerGeometryProperties: UserWalletView.ContainerGeometryProperties
    private(set) var refreshingUserWalletIDs: Set<UserWalletId>

    private(set) var isHorizontalScrollDisabled: Bool {
        didSet {
            collectionView.isScrollEnabled = !isHorizontalScrollDisabled
        }
    }

    init(
        userWalletPageBuilders: [MainUserWalletPageBuilder],
        selectedCardIndex: Binding<Int>,
        onSelectedCardChanged: @escaping (CardsInfoPageChangeReason) -> Void,
        containerGeometryProperties: UserWalletView.ContainerGeometryProperties,
        pullToRefreshAction: @MainActor @escaping (UserWalletId) -> Void,
        refreshingUserWalletIDs: Set<UserWalletId>,
        isHorizontalScrollDisabled: Bool,
        onContentPropertiesChanged: @escaping (UserWalletId, UserWalletView.ScrollContentProperties) -> Void,
        onPagingIndicatorOffsetChanged: @escaping (UserWalletId, UserWalletView.PagingIndicatorOffset) -> Void,
        onPagePositionChanged: @escaping (CGFloat) -> Void
    ) {
        self.userWalletPageBuilders = userWalletPageBuilders

        self.selectedCardIndex = selectedCardIndex
        currentCollectionViewIndex = selectedCardIndex.wrappedValue
        self.onSelectedCardChanged = onSelectedCardChanged

        self.containerGeometryProperties = containerGeometryProperties
        self.pullToRefreshAction = pullToRefreshAction
        self.refreshingUserWalletIDs = refreshingUserWalletIDs
        self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
        self.onContentPropertiesChanged = onContentPropertiesChanged
        self.onPagingIndicatorOffsetChanged = onPagingIndicatorOffsetChanged
        self.onPagePositionChanged = onPagePositionChanged

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        applyDatasourceSnapshot(completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !didPerformInitialScroll else { return }
        didPerformInitialScroll = true

        let selectedIndex = selectedCardIndex.wrappedValue
        currentCollectionViewIndex = selectedIndex
        scroll(to: selectedIndex, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layout.itemSize = collectionView.bounds.size
        layout.invalidateLayout()
    }

    func update(by coordinator: MainHorizontalPagingScrollView.HorizontalPagingScrollViewBackport.Coordinator) {
        let oldBuilders = userWalletPageBuilders
        let newBuilders = coordinator.userWalletPageBuilders
        let targetSelectedIndex = coordinator.selectedCardIndex

        let pageBuildersChanged = !oldBuilders.shallowEqual(to: newBuilders)

        let geometryChanged = containerGeometryProperties != coordinator.containerGeometryProperties

        let selectedIndexChanged = targetSelectedIndex != currentCollectionViewIndex

        let userWalletIDsWithChangedRefreshState = refreshingUserWalletIDs
            .symmetricDifference(coordinator.refreshingUserWalletIDs)

        isHorizontalScrollDisabled = coordinator.isHorizontalScrollDisabled

        userWalletPageBuilders = newBuilders
        containerGeometryProperties = coordinator.containerGeometryProperties
        refreshingUserWalletIDs = coordinator.refreshingUserWalletIDs

        let viewIsAlreadyInHierarchy = view.window != nil

        guard !pageBuildersChanged else {
            let itemsToReconfigure = changedExistingItems(from: oldBuilders, to: newBuilders)
                + userWalletIDsWithChangedRefreshState.map { ItemIdentifier(userWalletID: $0) }

            applyDatasourceSnapshot(
                reconfiguring: itemsToReconfigure,
                completion: { [weak self] in
                    guard let self else { return }
                    currentCollectionViewIndex = targetSelectedIndex
                    scroll(to: targetSelectedIndex, animated: viewIsAlreadyInHierarchy)
                }
            )

            return
        }

        var userWalletIDsToReconfigure = userWalletIDsWithChangedRefreshState

        if geometryChanged, userWalletPageBuilders.indices.contains(currentCollectionViewIndex) {
            userWalletIDsToReconfigure.insert(userWalletPageBuilders[currentCollectionViewIndex].id)
        }

        reconfigureItems(with: userWalletIDsToReconfigure)

        if selectedIndexChanged {
            currentCollectionViewIndex = targetSelectedIndex
            scroll(to: targetSelectedIndex, animated: viewIsAlreadyInHierarchy)
        }
    }

    private func applyDatasourceSnapshot(
        reconfiguring itemsToReconfigure: [ItemIdentifier] = [],
        completion: (() -> Void)?
    ) {
        let section = SectionIdentifier.userWallets
        let items = userWalletPageBuilders.map { ItemIdentifier(userWalletID: $0.id) }

        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>()
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)

        let validItemsToReconfigure = Array(Set(itemsToReconfigure).intersection(items))

        if !validItemsToReconfigure.isEmpty {
            snapshot.reconfigureItems(validItemsToReconfigure)
        }

        dataSource.apply(snapshot, animatingDifferences: false, completion: completion)
    }

    private func reconfigureItems(with userWalletIDs: Set<UserWalletId>) {
        guard userWalletIDs.isNotEmpty else { return }

        var snapshot = dataSource.snapshot()
        let items = userWalletIDs
            .map { ItemIdentifier(userWalletID: $0) }
            .filter { snapshot.indexOfItem($0) != nil }

        guard items.isNotEmpty else { return }

        snapshot.reconfigureItems(items)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func changedExistingItems(
        from oldPageBuilders: [MainUserWalletPageBuilder],
        to newPageBuilders: [MainUserWalletPageBuilder]
    ) -> [ItemIdentifier] {
        let userWalletIDToOldBuilder = Dictionary(uniqueKeysWithValues: oldPageBuilders.map { ($0.id, $0) })

        return newPageBuilders.compactMap { newPageBuilder -> ItemIdentifier? in
            guard let existingPageBuilder = userWalletIDToOldBuilder[newPageBuilder.id] else { return nil }

            return MainUserWalletPageBuilder.shallowEqual(lhs: existingPageBuilder, rhs: newPageBuilder)
                ? nil
                : ItemIdentifier(userWalletID: newPageBuilder.id)
        }
    }

    private func scroll(to index: Int, animated: Bool) {
        guard
            userWalletPageBuilders.indices.contains(index),
            visibleIndex() != index
        else {
            return
        }

        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    private func visibleIndex() -> Int? {
        guard let index = pagePosition().map({ Int($0.rounded()) }) else { return nil }

        return userWalletPageBuilders.indices.contains(index) ? index : nil
    }

    /// Horizontal position of the collection view, measured in page widths: `1.5` means the swipe is halfway between
    /// the second and the third page.
    private func pagePosition() -> CGFloat? {
        guard collectionView.bounds.width > .zero else { return nil }

        return collectionView.contentOffset.x / collectionView.bounds.width
    }

    private func setupCollectionView() {
        collectionView.clipsToBounds = false
        collectionView.layer.masksToBounds = false

        collectionView.delegate = self
        collectionView.isScrollEnabled = !isHorizontalScrollDisabled

        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UICollectionViewDelegate conformance

extension HorizontalPagingCollectionViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let pagePosition = pagePosition() else { return }

        onPagePositionChanged(pagePosition)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedIndex()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateSelectedIndex()
    }

    private func updateSelectedIndex() {
        guard let selectedIndex = visibleIndex() else { return }

        guard currentCollectionViewIndex != selectedIndex else { return }
        currentCollectionViewIndex = selectedIndex

        guard selectedCardIndex.wrappedValue != selectedIndex else { return }
        selectedCardIndex.wrappedValue = selectedIndex
        onSelectedCardChanged(.byGesture)
    }
}

// MARK: - Factory methods

extension HorizontalPagingCollectionViewController {
    private func makeDataSource(for collectionView: UICollectionView) -> DataSource {
        let cellRegistration = CellRegistration { [weak self] cell, indexPath, pageBuilder in
            guard let self else { return }

            return cell.contentConfiguration = UIHostingConfiguration {
                UserWalletView(
                    pageBuilder: pageBuilder,
                    showPagingIndicatorStub: self.userWalletPageBuilders.count > 1,
                    isRefreshing: self.refreshingUserWalletIDs.contains(pageBuilder.id),
                    pullToRefreshAction: { [weak self] in
                        self?.pullToRefreshAction(pageBuilder.id)
                    },
                    onContentPropertiesChanged: { [weak self] contentProperties in
                        self?.onContentPropertiesChanged(pageBuilder.id, contentProperties)
                    },
                    onPagingIndicatorOffsetChanged: { [weak self] pagingIndicatorOffset in
                        self?.onPagingIndicatorOffsetChanged(pageBuilder.id, pagingIndicatorOffset)
                    },
                    containerGeometryProperties: self.containerGeometryProperties
                )
            }
            .margins(.all, .zero)
        }

        return DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self, userWalletPageBuilders.indices.contains(indexPath.item) else {
                return UICollectionViewCell()
            }

            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: userWalletPageBuilders[indexPath.item]
            )
        }
    }

    private static func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = .zero
        layout.minimumInteritemSpacing = .zero
        return layout
    }

    private static func makeCollectionView(with layout: UICollectionViewLayout) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear

        return collectionView
    }
}

// MARK: - Nested types

extension HorizontalPagingCollectionViewController {
    private enum SectionIdentifier: Hashable {
        case userWallets
    }

    private struct ItemIdentifier: Hashable {
        let userWalletID: UserWalletId
    }
}

private extension MainUserWalletPageBuilder {
    var bodyViewModel: AnyObject? {
        switch self {
        case .singleWallet(_, _, _, let bodyViewModel): bodyViewModel
        case .multiWallet(_, _, _, let bodyViewModel): bodyViewModel
        case .lockedWallet(_, _, _, let bodyViewModel): bodyViewModel
        case .visaWallet(_, _, _, let bodyViewModel): bodyViewModel
        }
    }

    static func shallowEqual(lhs: MainUserWalletPageBuilder, rhs: MainUserWalletPageBuilder) -> Bool {
        switch (lhs.bodyViewModel, rhs.bodyViewModel) {
        case (.some(let lhsViewModel), .some(let rhsViewModel)):
            lhsViewModel === rhsViewModel

        case (.some, .none):
            false

        case (.none, .some):
            false

        case (.none, .none):
            true
        }
    }
}

private extension [MainUserWalletPageBuilder] {
    func shallowEqual(to other: Self) -> Bool {
        guard count == other.count else { return false }
        return Swift.zip(self, other).allSatisfy(MainUserWalletPageBuilder.shallowEqual)
    }
}
