//
//  OrganizeTokensDragAndDropController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

enum OrganizeTokensDragAndDropControllerListViewKind {
    case cell
    case sectionHeader
}

protocol OrganizeTokensDragAndDropControllerDataSource: AnyObject {
    func numberOfSections(
        for controller: OrganizeTokensDragAndDropController
    ) -> Int

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfRowsInSection section: Int
    ) -> Int

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: IndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind
}

final class OrganizeTokensDragAndDropController: ObservableObject {
    weak var dataSource: OrganizeTokensDragAndDropControllerDataSource?

    private var itemsFrames: [IndexPath: CGRect] = [:]

    private lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    func onDragPrepare() {
        selectionFeedbackGenerator.prepare()
    }

    func onDragStart() {
        selectionFeedbackGenerator.selectionChanged()
        impactFeedbackGenerator.prepare()
    }

    func onItemsMove() {
        impactFeedbackGenerator.impactOccurred()
    }

    func scrollTarget(sourceLocation: CGPoint, currentLocation: CGPoint) -> UUID? {
        // [REDACTED_TODO_COMMENT]
        return nil
    }

    func saveFrame(_ frame: CGRect, forItemAt indexPath: IndexPath) {
        itemsFrames[indexPath] = frame
    }

    func frame(forItemAt indexPath: IndexPath?) -> CGRect? {
        indexPath.flatMap { itemsFrames[$0] }
    }

    func indexPath(for location: CGPoint) -> IndexPath? {
        return itemsFrames
            .first { isIndexPathValid($0.key) && $0.value.contains(location) }
            .map(\.key)
    }

    func updatedDestinationIndexPath(
        source sourceIndexPath: IndexPath,
        currentDestination currentDestinationIndexPath: IndexPath,
        translationValue: CGSize
    ) -> IndexPath? {
        guard let dataSource = dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return nil
        }
        guard var draggedItemFrame = frame(forItemAt: sourceIndexPath) else {
            return nil
        }

        draggedItemFrame.origin.y += translationValue.height
        let neighboringIndexPaths: [IndexPath]

        switch dataSource.controller(self, listViewKindForItemAt: sourceIndexPath) {
        case .cell:
            neighboringIndexPaths = neighboringItemsIndexPaths(
                forItemAt: currentDestinationIndexPath,
                dataSource: dataSource
            )
        case .sectionHeader:
            neighboringIndexPaths = neighboringSectionsIndexPaths(
                forSectionAt: currentDestinationIndexPath,
                dataSource: dataSource
            )
        }

        return neighboringIndexPaths
            .first { neighboringIndexPath in
                guard let neighboringItemFrame = frame(forItemAt: neighboringIndexPath) else {
                    return false
                }

                let intersection = draggedItemFrame.intersection(neighboringItemFrame)

                return !intersection.isNull && intersection.height > neighboringItemFrame.height
                    * Constants.destinationItemSelectionFrameHeightThresholdRatio
            }
    }

    private func neighboringItemsIndexPaths(
        forItemAt indexPath: IndexPath,
        dataSource: OrganizeTokensDragAndDropControllerDataSource
    ) -> [IndexPath] {
        var neighboringItemsIndexPaths: [IndexPath] = []

        if indexPath.item > 0 {
            neighboringItemsIndexPaths.append(
                IndexPath(item: indexPath.item - 1, section: indexPath.section)
            )
        }

        let numberOfRowsInSection = dataSource.controller(self, numberOfRowsInSection: indexPath.section)
        if indexPath.item < numberOfRowsInSection - 1 {
            neighboringItemsIndexPaths.append(
                IndexPath(item: indexPath.item + 1, section: indexPath.section)
            )
        }

        return neighboringItemsIndexPaths
    }

    private func neighboringSectionsIndexPaths(
        forSectionAt indexPath: IndexPath,
        dataSource: OrganizeTokensDragAndDropControllerDataSource
    ) -> [IndexPath] {
        var neighboringSectionsIndexPaths: [IndexPath] = []

        if indexPath.section > 0 {
            neighboringSectionsIndexPaths.append(
                IndexPath(item: indexPath.item, section: indexPath.section - 1)
            )
        }

        let numberOfSections = dataSource.numberOfSections(for: self)
        if indexPath.section < numberOfSections - 1 {
            neighboringSectionsIndexPaths.append(
                IndexPath(item: indexPath.item, section: indexPath.section + 1)
            )
        }

        return neighboringSectionsIndexPaths
    }

    // Maybe not so memory-efficient, but definitely safer than manual clearing of `itemsFrames` cache
    private func isIndexPathValid(_ indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return false
        }

        let isSectionValid = 0 ..< dataSource.numberOfSections(for: self) ~= indexPath.section
        let listViewKind = dataSource.controller(self, listViewKindForItemAt: indexPath)

        switch listViewKind {
        case .cell:
            let numberOfRowsInSection = dataSource.controller(self, numberOfRowsInSection: indexPath.section)
            return isSectionValid && 0 ..< numberOfRowsInSection ~= indexPath.item
        case .sectionHeader:
            return isSectionValid
        }
    }
}

// MARK: - Constants

private extension OrganizeTokensDragAndDropController {
    enum Constants {
        static let destinationItemSelectionFrameHeightThresholdRatio = 0.5
    }
}
