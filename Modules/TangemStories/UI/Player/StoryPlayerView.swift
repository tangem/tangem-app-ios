//
//  StoryPlayerView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers

public struct StoryPlayerView: View {
    @ObservedObject var vm: StoryPlayerViewModel

    public init(vm: StoryPlayerViewModel) {
        self.vm = vm
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Hidden neighbours stay mounted so their layers hold a decoded first frame.
            ZStack {
                ForEach(vm.preparedSlides) { slide in
                    SlideStage(vm: slide, isVisible: slide.id == vm.current.id)
                        .opacity(slide.id == vm.current.id ? 1 : 0)
                }
            }
            .ignoresSafeArea()
            .accessibilityIdentifier(StoriesAccessibilityIdentifiers.storyContainer)

            StoryScrimView()

            StoryTapNavigationView(
                onBackward: vm.tapBackward,
                onForward: vm.tapForward,
                onHoldChanged: { holding in vm.setPaused(holding, for: .hold) },
                onSwipeDown: vm.swipeDown
            )

            VStack(spacing: .zero) {
                ZStack {
                    StorySegmentedProgressBar(
                        slides: vm.story.slides.count,
                        currentIndex: vm.currentIndex,
                        progress: vm.current.progress
                    )

                    StoriesCloseButton(action: vm.closeButtonTapped)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer(minLength: .zero)

                VStack(spacing: 40) {
                    // `.id` swaps the block per slide so old and new text cross-fade.
                    ZStack {
                        StoryTitleView(title: vm.current.slide.title, subtitle: vm.current.slide.subtitle)
                            .id(vm.current.id)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: Constants.titleCrossFadeDuration), value: vm.current.id)

                    StoryActionsView(actions: currentActions, onTap: vm.actionTapped)
                }
            }
        }
        .preferredColorScheme(.dark)
        .background(Color.black)
        .onAppear {
            vm.start()
            vm.viewAppeared()
        }
        .onDisappear { vm.viewDisappeared() }
    }

    private var currentActions: [StoryActionV2] {
        vm.current.slide.actions ?? vm.story.actions
    }

    private enum Constants {
        static let titleCrossFadeDuration: Double = 0.25
    }
}
