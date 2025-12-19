//
//  AccountsAwareOrganizeTokensDragAndDropController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt

// [REDACTED_TODO_COMMENT]
protocol AccountsAwareOrganizeTokensDragAndDropControllerDataSource: AnyObject {
    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        numberOfInnerSectionsInOuterSection outerSection: Int
    ) -> Int

    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        numberOfRowsInInnerSection innerSection: Int,
        andOuterSection outerSection: Int
    ) -> Int

    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: OrganizeTokensIndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind

    func controller(
        _ controller: AccountsAwareOrganizeTokensDragAndDropController,
        listViewIdentifierForItemAt indexPath: OrganizeTokensIndexPath
    ) -> AnyHashable
}

// [REDACTED_TODO_COMMENT]
final class AccountsAwareOrganizeTokensDragAndDropController: ObservableObject {
    weak var dataSource: AccountsAwareOrganizeTokensDragAndDropControllerDataSource?

    private(set) var autoScrollStatus: OrganizeTokensDragAndDropControllerAutoScrollStatus = .inactive

    private(set) lazy var autoScrollTargetPublisher: some Publisher<AnyHashable, Never> = autoScrollStartSubject
        .withWeakCaptureOf(self)
        .flatMapLatest { controller, direction in
            // The first item from `additionalAutoScrollTargets` is emitted immediately
            // to get rid of delays between ticks of two separate timers
            let additionalAutoScrollTargets = controller.additionalAutoScrollTargets(scrollDirection: direction)
            let additionalAutoScrollTargetsPublisher = Timer
                .publish(every: controller.autoScrollFrequency, on: .main, in: .common)
                .autoconnect()
                .zip(additionalAutoScrollTargets.dropFirst(1).publisher)
                .map(\.1)
                .prepend(additionalAutoScrollTargets.prefix(1))

            return Timer
                .publish(every: controller.autoScrollFrequency, on: .main, in: .common)
                .autoconnect()
                .withLatestFrom(controller._contentOffsetSubject, controller._viewportSizeSubject)
                .withWeakCaptureOf(controller)
                .map { input -> AnyHashable? in
                    let (controller, (contentOffset, viewportSize)) = input
                    let scrollTargetIndexPath = controller.indexPathForAutoScrollTarget(
                        direction: direction,
                        contentOffset: contentOffset,
                        viewportSize: viewportSize
                    )
                    return scrollTargetIndexPath.flatMap { indexPath in
                        controller.dataSource?.controller(controller, listViewIdentifierForItemAt: indexPath)
                    }
                }
                .prefix { $0 != nil }
                .compactMap { $0 }
                .append(additionalAutoScrollTargetsPublisher)
                .removeDuplicates()
                .prefix(untilOutputFrom: controller.autoScrollStopSubject)
        }
    // Fix for SwiftUI preview crashes due to unsafe handling of a recursive lock by the Swift TypeChecker
    #if targetEnvironment(simulator)
        .eraseToAnyPublisher()
    #endif // targetEnvironment(simulator)

    var viewportSizeSubject: some Subject<CGSize, Never> { _viewportSizeSubject }
    private let _viewportSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    private var itemsFrames: [OrganizeTokensIndexPath: CGRect] = [:]

    private let autoScrollStartSubject = PassthroughSubject<OrganizeTokensDragAndDropControllerAutoScrollDirection, Never>()
    private let autoScrollStopSubject = PassthroughSubject<Void, Never>()

    private let autoScrollFrequency: TimeInterval
    private let destinationItemSelectionThresholdRatio: Double

    private let topEdgeAdditionalAutoScrollTargets: [AnyHashable]
    private let bottomEdgeAdditionalAutoScrollTargets: [AnyHashable]

    private lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var selectionFeedbackGenerator = UISelectionFeedbackGenerator()

    init(
        autoScrollFrequency: TimeInterval,
        destinationItemSelectionThresholdRatio: Double,
        topEdgeAdditionalAutoScrollTargets: [AnyHashable] = [],
        bottomEdgeAdditionalAutoScrollTargets: [AnyHashable] = []
    ) {
        self.autoScrollFrequency = autoScrollFrequency
        self.destinationItemSelectionThresholdRatio = destinationItemSelectionThresholdRatio
        self.topEdgeAdditionalAutoScrollTargets = topEdgeAdditionalAutoScrollTargets
        self.bottomEdgeAdditionalAutoScrollTargets = bottomEdgeAdditionalAutoScrollTargets
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

    func saveFrame(_ frame: CGRect, forItemAt indexPath: OrganizeTokensIndexPath) {
        itemsFrames[indexPath] = frame
    }

    func frame(forItemAt indexPath: OrganizeTokensIndexPath) -> CGRect? {
        itemsFrames[indexPath]
    }

    func updatedDestinationIndexPath(
        source sourceIndexPath: OrganizeTokensIndexPath,
        currentDestination currentDestinationIndexPath: OrganizeTokensIndexPath,
        translationValue: CGSize
    ) -> OrganizeTokensIndexPath? {
        guard let dataSource = dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return nil
        }
        guard var draggedItemFrame = frame(forItemAt: sourceIndexPath) else {
            return nil
        }

        draggedItemFrame.origin.y += translationValue.height

        switch dataSource.controller(self, listViewKindForItemAt: sourceIndexPath) {
        case .cell:
            return updatedDestinationIndexPath(
                forItemAt: currentDestinationIndexPath,
                draggedItemFrame: draggedItemFrame,
                dataSource: dataSource
            )
        case .sectionHeader:
            return updatedDestinationIndexPath(
                forSectionAt: currentDestinationIndexPath,
                draggedItemFrame: draggedItemFrame,
                dataSource: dataSource
            )
        }
    }

    func startAutoScrolling(direction: OrganizeTokensDragAndDropControllerAutoScrollDirection) {
        guard !autoScrollStatus.isActive else { return }

        autoScrollStatus = .active(direction: direction)
        autoScrollStartSubject.send(direction)
    }

    func stopAutoScrolling() {
        guard autoScrollStatus.isActive else { return }

        autoScrollStopSubject.send()
        autoScrollStatus = .inactive
    }

    /// - Warning: O(N) time complexity.
    private func updatedDestinationIndexPath(
        forItemAt indexPath: OrganizeTokensIndexPath,
        draggedItemFrame: CGRect,
        dataSource: AccountsAwareOrganizeTokensDragAndDropControllerDataSource
    ) -> OrganizeTokensIndexPath? {
        let numberOfRowsInSection = dataSource.controller(
            self,
            numberOfRowsInInnerSection: indexPath.innerSection,
            andOuterSection: indexPath.outerSection
        )
        var hasReachedTop = false
        var hasReachedBottom = false

        for offset in 1 ..< numberOfRowsInSection {
            // Going in the upward direction from the current destination index path until OOB
            if !hasReachedTop, indexPath.item - offset >= 0 {
                let destinationIndexPathCandidate = OrganizeTokensIndexPath(
                    outerSection: indexPath.outerSection,
                    innerSection: indexPath.innerSection,
                    item: indexPath.item - offset
                )
                if isDestinationIndexPathCandidateValid(destinationIndexPathCandidate, draggedItemFrame: draggedItemFrame) {
                    return destinationIndexPathCandidate
                }
            } else {
                hasReachedTop = true
            }

            // Going in the downward direction from the current destination index path until OOB
            if !hasReachedBottom, indexPath.item + offset <= numberOfRowsInSection - 1 {
                let destinationIndexPathCandidate = OrganizeTokensIndexPath(
                    outerSection: indexPath.outerSection,
                    innerSection: indexPath.innerSection,
                    item: indexPath.item + offset
                )
                if isDestinationIndexPathCandidateValid(destinationIndexPathCandidate, draggedItemFrame: draggedItemFrame) {
                    return destinationIndexPathCandidate
                }
            } else {
                hasReachedBottom = true
            }

            if hasReachedTop, hasReachedBottom {
                return nil
            }
        }

        return nil
    }

    /// - Warning: O(N) time complexity.
    private func updatedDestinationIndexPath(
        forSectionAt indexPath: OrganizeTokensIndexPath,
        draggedItemFrame: CGRect,
        dataSource: AccountsAwareOrganizeTokensDragAndDropControllerDataSource
    ) -> OrganizeTokensIndexPath? {
        let numberOfSections = dataSource.controller(self, numberOfInnerSectionsInOuterSection: indexPath.outerSection)
        var hasReachedTop = false
        var hasReachedBottom = false

        for offset in 1 ..< numberOfSections {
            // Going in the upward direction from the current destination index path until OOB
            if !hasReachedTop, indexPath.innerSection - offset >= 0 {
                let destinationIndexPathCandidate = OrganizeTokensIndexPath(
                    outerSection: indexPath.outerSection,
                    innerSection: indexPath.innerSection - offset,
                    item: indexPath.item
                )
                if isDestinationIndexPathCandidateValid(destinationIndexPathCandidate, draggedItemFrame: draggedItemFrame) {
                    return destinationIndexPathCandidate
                }
            } else {
                hasReachedTop = true
            }

            // Going in the downward direction from the current destination index path until OOB
            if !hasReachedBottom, indexPath.innerSection + offset <= numberOfSections - 1 {
                let destinationIndexPathCandidate = OrganizeTokensIndexPath(
                    outerSection: indexPath.outerSection,
                    innerSection: indexPath.innerSection + offset,
                    item: indexPath.item
                )
                if isDestinationIndexPathCandidateValid(destinationIndexPathCandidate, draggedItemFrame: draggedItemFrame) {
                    return destinationIndexPathCandidate
                }
            } else {
                hasReachedBottom = true
            }

            if hasReachedTop, hasReachedBottom {
                return nil
            }
        }

        return nil
    }

    func isDestinationIndexPathCandidateValid(
        _ destinationIndexPathCandidate: OrganizeTokensIndexPath,
        draggedItemFrame: CGRect
    ) -> Bool {
        guard let candidateItemFrame = frame(forItemAt: destinationIndexPathCandidate) else {
            return false
        }

        let intersection = draggedItemFrame.intersection(candidateItemFrame)
        let ratio = destinationItemSelectionThresholdRatio

        return !intersection.isNull && intersection.height > candidateItemFrame.height * ratio
    }

    /// Maybe not so memory-efficient, but definitely safer than manual clearing of `itemsFrames` cache
    private func isIndexPathValid(_ indexPath: OrganizeTokensIndexPath) -> Bool {
        guard let dataSource = dataSource else {
            assertionFailure("DataSource required, but not set for \(self)")
            return false
        }

        let numberOfSections = dataSource.controller(self, numberOfInnerSectionsInOuterSection: indexPath.outerSection)
        let isSectionValid = 0 ..< numberOfSections ~= indexPath.innerSection
        let listViewKind = dataSource.controller(self, listViewKindForItemAt: indexPath)

        switch listViewKind {
        case .cell where isSectionValid:
            let numberOfRowsInSection = dataSource.controller(
                self,
                numberOfRowsInInnerSection: indexPath.innerSection,
                andOuterSection: indexPath.outerSection
            )
            return 0 ..< numberOfRowsInSection ~= indexPath.item
        case .cell, .sectionHeader:
            return isSectionValid
        }
    }

    /// - Warning: O(N) time complexity.
    private func indexPathForAutoScrollTarget(
        direction: OrganizeTokensDragAndDropControllerAutoScrollDirection,
        contentOffset: CGPoint,
        viewportSize: CGSize
    ) -> OrganizeTokensIndexPath? {
        // [REDACTED_TODO_COMMENT]
        let sortedItemsFrames = itemsFrames
            .filter { isIndexPathValid($0.key) }
            .sorted(by: \.value.minY)

        switch direction {
        case .top:
            if let lastValidTargetAtTheTop = sortedItemsFrames.last(where: { key, value in
                value.minY.rounded() < contentOffset.y.rounded() - .ulpOfOne
            }) {
                return lastValidTargetAtTheTop.key
            }
        case .bottom:
            if let firstValidTargetAtTheBottom = sortedItemsFrames.first(where: { key, value in
                value.maxY.rounded() > contentOffset.y.rounded() + viewportSize.height.rounded() - .ulpOfOne
            }) {
                return firstValidTargetAtTheBottom.key
            }
        }

        return nil
    }

    private func additionalAutoScrollTargets(
        scrollDirection: OrganizeTokensDragAndDropControllerAutoScrollDirection
    ) -> [AnyHashable] {
        switch scrollDirection {
        case .top:
            // We're scrolling to the top, so items at the bottom come first - therefore reversed order is used
            return topEdgeAdditionalAutoScrollTargets.reversed()
        case .bottom:
            return bottomEdgeAdditionalAutoScrollTargets
        }
    }
}
