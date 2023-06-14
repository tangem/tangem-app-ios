//
//  OrganizeTokensDragAndDropController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

protocol OrganizeTokensDragAndDropControllerDataSource: AnyObject {
    func numberOfSections(
        for controller: OrganizeTokensDragAndDropController
    ) -> Int

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfRowsInSection: Int
    ) -> Int
}

final class OrganizeTokensDragAndDropController: ObservableObject {
    weak var dataSource: OrganizeTokensDragAndDropControllerDataSource?

    private let cellSelectionThresholdHeight: CGFloat
    private var frames: [IndexPath: CGRect] = [:]

    private lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    init(cellSelectionThresholdHeight: CGFloat) {
        self.cellSelectionThresholdHeight = cellSelectionThresholdHeight
    }

    func saveFrame(_ frame: CGRect, forItemAtIndexPath indexPath: IndexPath) {
        frames[indexPath] = frame
    }

    func frame(forItemAtIndexPath indexPath: IndexPath?) -> CGRect? {
        indexPath.flatMap { frames[$0] }
    }

    func indexPath(forLocation location: CGPoint) -> IndexPath? {
        return frames
            .first { $0.value.contains(location) }
            .map(\.key)
    }

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

        let currentSection = currentDestinationIndexPath.section
        let currentItem = currentDestinationIndexPath.item

        var neighboringCellsIndexPaths: [IndexPath] = []
        if currentItem > 0 {
            neighboringCellsIndexPaths.append(
                IndexPath(item: currentItem - 1, section: currentSection)
            )
        }

        let numberOfRowsInSection = dataSource.controller(self, numberOfRowsInSection: currentSection)
        if currentItem < numberOfRowsInSection - 1 {
            neighboringCellsIndexPaths.append(
                IndexPath(item: currentItem + 1, section: currentSection)
            )
        }

        return neighboringCellsIndexPaths
            .first { neighboringCellIndexPath in
                guard let neighboringCellFrame = frame(forItemAtIndexPath: neighboringCellIndexPath) else {
                    return false
                }

                let intersection = draggedCellFrame.intersection(neighboringCellFrame)

                return !intersection.isNull && intersection.height > cellSelectionThresholdHeight
            }
    }
}
