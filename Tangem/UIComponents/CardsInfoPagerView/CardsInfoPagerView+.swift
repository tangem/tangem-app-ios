//
//  CardsInfoPagerView+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

// MARK: - Convenience initializers

extension CardsInfoPagerView where BottomOverlay == EmptyView {
    init(
        data: Data,
        id idProvider: KeyPath<(Data.Index, Data.Element), ID>,
        refreshScrollViewStateObject: RefreshScrollViewStateObject?,
        selectedIndex: Binding<Int>,
        discoveryAnimationTrigger: CardsInfoPagerSwipeDiscoveryAnimationTrigger = .dummy,
        configStorageKey: AnyHashable = #fileID,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory
    ) {
        self.init(
            data: data,
            id: idProvider,
            refreshScrollViewStateObject: refreshScrollViewStateObject,
            selectedIndex: selectedIndex,
            discoveryAnimationTrigger: discoveryAnimationTrigger,
            configStorageKey: configStorageKey,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            bottomOverlayFactory: { _, _ in EmptyView() },
        )
    }
}

extension CardsInfoPagerView where Data.Element: Identifiable, Data.Element.ID == ID {
    init(
        data: Data,
        refreshScrollViewStateObject: RefreshScrollViewStateObject?,
        selectedIndex: Binding<Int>,
        discoveryAnimationTrigger: CardsInfoPagerSwipeDiscoveryAnimationTrigger = .dummy,
        configStorageKey: AnyHashable = #fileID,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory,
        @ViewBuilder bottomOverlayFactory: @escaping BottomOverlayFactory
    ) {
        self.init(
            data: data,
            id: \.1.id,
            refreshScrollViewStateObject: refreshScrollViewStateObject,
            selectedIndex: selectedIndex,
            discoveryAnimationTrigger: discoveryAnimationTrigger,
            configStorageKey: configStorageKey,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            bottomOverlayFactory: bottomOverlayFactory,
        )
    }
}

extension CardsInfoPagerView where Data.Element: Identifiable, Data.Element.ID == ID, BottomOverlay == EmptyView {
    init(
        data: Data,
        refreshScrollViewStateObject: RefreshScrollViewStateObject?,
        selectedIndex: Binding<Int>,
        discoveryAnimationTrigger: CardsInfoPagerSwipeDiscoveryAnimationTrigger = .dummy,
        configStorageKey: AnyHashable = #fileID,
        @ViewBuilder headerFactory: @escaping HeaderFactory,
        @ViewBuilder contentFactory: @escaping ContentFactory
    ) {
        self.init(
            data: data,
            id: \.1.id,
            refreshScrollViewStateObject: refreshScrollViewStateObject,
            selectedIndex: selectedIndex,
            discoveryAnimationTrigger: discoveryAnimationTrigger,
            configStorageKey: configStorageKey,
            headerFactory: headerFactory,
            contentFactory: contentFactory,
            bottomOverlayFactory: { _, _ in EmptyView() },
        )
    }
}

// MARK: - Auxiliary types

enum CardsInfoPageChangeReason {
    case byGesture
    case programmatically
}

// MARK: - Convenience extensions

private extension CardsInfoPagerSwipeDiscoveryAnimationTrigger {
    static let dummy: CardsInfoPagerSwipeDiscoveryAnimationTrigger = .init()
}
