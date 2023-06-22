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
        listViewKindForIndexPath indexPath: IndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind
}

final class OrganizeTokensDragAndDropController: ObservableObject {
    weak var dataSource: OrganizeTokensDragAndDropControllerDataSource?

    private var frames: [IndexPath: CGRect] = [:]

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

    func saveFrame(_ frame: CGRect, forItemAtIndexPath indexPath: IndexPath) {
        frames[indexPath] = frame
    }

    func frame(forItemAtIndexPath indexPath: IndexPath?) -> CGRect? {
        indexPath.flatMap { frames[$0] }
    }

    func indexPath(forLocation location: CGPoint) -> IndexPath? {
        return frames
            .first { isIndexPathValid($0.key) && $0.value.contains(location) }
            .map(\.key)
    }

    func updatedDestinationIndexPathForDragAndDrop(
        sourceIndexPath: IndexPath,
        currentDestinationIndexPath: IndexPath,
        translationValue: CGSize
    ) -> IndexPath? {
        guard let dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return nil
        }

        guard var draggedCellFrame = frame(forItemAtIndexPath: sourceIndexPath) else {
            return nil
        }

        draggedCellFrame.origin.y += translationValue.height
        let neighboringIndexPaths: [IndexPath]

        switch dataSource.controller(self, listViewKindForIndexPath: sourceIndexPath) {
        case .cell:
            neighboringIndexPaths = neighboringCellsIndexPaths(
                forCellAtIndexPath: currentDestinationIndexPath,
                dataSource: dataSource
            )
        case .sectionHeader:
            neighboringIndexPaths = neighboringSectionsIndexPaths(
                forSectionAtIndexPath: currentDestinationIndexPath,
                dataSource: dataSource
            )
        }

        return neighboringIndexPaths
            .first { neighboringCellIndexPath in
                guard let neighboringCellFrame = frame(forItemAtIndexPath: neighboringCellIndexPath) else {
                    return false
                }

                let intersection = draggedCellFrame.intersection(neighboringCellFrame)

                return !intersection.isNull && intersection.height > neighboringCellFrame.height
                    * Constants.destinationCellSelectionFrameHeigthThresholdRatio
                    - Constants.destinationCellSelectionFrameHeigthThresholdDiff
            }
    }

    private func neighboringCellsIndexPaths(
        forCellAtIndexPath indexPath: IndexPath,
        dataSource: OrganizeTokensDragAndDropControllerDataSource
    ) -> [IndexPath] {
        var neighboringCellsIndexPaths: [IndexPath] = []

        if indexPath.item > 0 {
            neighboringCellsIndexPaths.append(
                IndexPath(item: indexPath.item - 1, section: indexPath.section)
            )
        }

        let numberOfRowsInSection = dataSource.controller(self, numberOfRowsInSection: indexPath.section)
        if indexPath.item < numberOfRowsInSection - 1 {
            neighboringCellsIndexPaths.append(
                IndexPath(item: indexPath.item + 1, section: indexPath.section)
            )
        }

        return neighboringCellsIndexPaths
    }

    private func neighboringSectionsIndexPaths(
        forSectionAtIndexPath indexPath: IndexPath,
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

    // Maybe not so memory-efficient, but definitely safer than manual clearing of `frames` cache
    private func isIndexPathValid(_ indexPath: IndexPath) -> Bool {
        guard let dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return false
        }

        let isSectionValid = 0 ..< dataSource.numberOfSections(for: self) ~= indexPath.section
        let listViewKind = dataSource.controller(self, listViewKindForIndexPath: indexPath)

        switch listViewKind {
        case .cell:
            return isSectionValid && 0 ..< dataSource.controller(self, numberOfRowsInSection: indexPath.section) ~= indexPath.item
        case .sectionHeader:
            return isSectionValid
        }
    }
}

// MARK: - Constants

private extension OrganizeTokensDragAndDropController {
    enum Constants {
        static let destinationCellSelectionFrameHeigthThresholdRatio = 0.5
        static let destinationCellSelectionFrameHeigthThresholdDiff = 5.0
    }
}
