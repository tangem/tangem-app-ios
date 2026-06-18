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

            init(
                userWalletPageBuilders: [MainUserWalletPageBuilder],
                selectedCardIndex: Int,
                containerGeometryProperties: UserWalletView.ContainerGeometryProperties,
                isHorizontalScrollDisabled: Bool
            ) {
                self.userWalletPageBuilders = userWalletPageBuilders
                self.selectedCardIndex = selectedCardIndex
                self.containerGeometryProperties = containerGeometryProperties
                self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
            }
        }

        let userWalletPageBuilders: [MainUserWalletPageBuilder]

        let selectedCardIndex: Binding<Int>
        let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

        let containerGeometryProperties: UserWalletView.ContainerGeometryProperties

        let pullToRefreshAction: @MainActor () async -> Void
        let isHorizontalScrollDisabled: Bool
        let onContentPropertiesChanged: (UserWalletId, UserWalletView.ScrollContentProperties) -> Void
        let onNormalizedOffsetYChanged: (UserWalletId, CGFloat, Animation?) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex.wrappedValue,
                containerGeometryProperties: containerGeometryProperties,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled
            )
        }

        func makeUIViewController(context: Context) -> HorizontalPagingCollectionViewController {
            HorizontalPagingCollectionViewController(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                onSelectedCardChanged: onSelectedCardChanged,
                containerGeometryProperties: containerGeometryProperties,
                pullToRefreshAction: pullToRefreshAction,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentPropertiesChanged: onContentPropertiesChanged,
                onNormalizedOffsetYChanged: onNormalizedOffsetYChanged
            )
        }

        func updateUIViewController(_ uiViewController: HorizontalPagingCollectionViewController, context: Context) {
            context.coordinator.userWalletPageBuilders = userWalletPageBuilders
            context.coordinator.selectedCardIndex = selectedCardIndex.wrappedValue
            context.coordinator.containerGeometryProperties = containerGeometryProperties
            context.coordinator.isHorizontalScrollDisabled = isHorizontalScrollDisabled

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

    let pullToRefreshAction: @MainActor () async -> Void
    let onContentPropertiesChanged: (UserWalletId, UserWalletView.ScrollContentProperties) -> Void
    let onNormalizedOffsetYChanged: (UserWalletId, CGFloat, Animation?) -> Void

    private(set) var containerGeometryProperties: UserWalletView.ContainerGeometryProperties

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
        pullToRefreshAction: @MainActor @escaping () async -> Void,
        isHorizontalScrollDisabled: Bool,
        onContentPropertiesChanged: @escaping (UserWalletId, UserWalletView.ScrollContentProperties) -> Void,
        onNormalizedOffsetYChanged: @escaping (UserWalletId, CGFloat, Animation?) -> Void
    ) {
        self.userWalletPageBuilders = userWalletPageBuilders

        self.selectedCardIndex = selectedCardIndex
        currentCollectionViewIndex = selectedCardIndex.wrappedValue
        self.onSelectedCardChanged = onSelectedCardChanged

        self.containerGeometryProperties = containerGeometryProperties
        self.pullToRefreshAction = pullToRefreshAction
        self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
        self.onContentPropertiesChanged = onContentPropertiesChanged
        self.onNormalizedOffsetYChanged = onNormalizedOffsetYChanged

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

        isHorizontalScrollDisabled = coordinator.isHorizontalScrollDisabled

        userWalletPageBuilders = newBuilders
        containerGeometryProperties = coordinator.containerGeometryProperties

        let viewIsAlreadyInHierarchy = view.window != nil

        guard !pageBuildersChanged else {
            applyDatasourceSnapshot(
                reconfiguring: changedExistingItems(from: oldBuilders, to: newBuilders),
                completion: { [weak self] in
                    guard let self else { return }
                    currentCollectionViewIndex = targetSelectedIndex
                    scroll(to: targetSelectedIndex, animated: viewIsAlreadyInHierarchy)
                }
            )

            return
        }

        if geometryChanged {
            reconfigureCurrentItem()
        }

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

        let itemsSet = Set(items)
        let validItemsToReconfigure = itemsToReconfigure.filter(itemsSet.contains)

        if !validItemsToReconfigure.isEmpty {
            snapshot.reconfigureItems(validItemsToReconfigure)
        }

        dataSource.apply(snapshot, animatingDifferences: false, completion: completion)
    }

    private func reconfigureCurrentItem() {
        let selectedIndex = currentCollectionViewIndex

        guard userWalletPageBuilders.indices.contains(selectedIndex) else { return }

        var snapshot = dataSource.snapshot()
        let item = ItemIdentifier(userWalletID: userWalletPageBuilders[selectedIndex].id)

        guard snapshot.indexOfItem(item) != nil else { return }

        snapshot.reconfigureItems([item])
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
        guard collectionView.bounds.width > .zero else { return nil }

        let index = Int((collectionView.contentOffset.x / collectionView.bounds.width).rounded())
        return userWalletPageBuilders.indices.contains(index) ? index : nil
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
                    pullToRefreshAction: self.pullToRefreshAction,
                    onContentPropertiesChanged: { [weak self] contentProperties in
                        self?.onContentPropertiesChanged(pageBuilder.id, contentProperties)
                    },
                    onNormalizedOffsetYChanged: { [weak self] normalizedOffsetY, animation in
                        self?.onNormalizedOffsetYChanged(pageBuilder.id, normalizedOffsetY, animation)
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
