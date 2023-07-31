//
//  BottomSearchableSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class BottomSearchableSheetCoordinator: ObservableObject {
    @Published var bottomSheet: BottomSheetContainer_Previews.BottomSheetViewModel?

    func toggleItem() {
        if bottomSheet == nil {
            bottomSheet = .init { [weak self] in
                self?.bottomSheet = nil
            }
        } else {
            bottomSheet = nil
        }
    }
}

class BottomSearchableSheetStateObject: ObservableObject {
    @Published var geometryInfo: GeometryInfo = .init()

    @Published var percent: CGFloat = .zero {
        didSet {
            print("percent ->>", percent)
        }
    }

    @Published var state: SheetState = .top {
        didSet {
            print("state ->>", state)
        }
    }

    @Published var visibleHeight: CGFloat = 0 {
        didSet {
            print("visibleHeight ->>", visibleHeight)
            percent = (visibleHeight - headerSize - 34) / 500
        }
    }

    @Published var scrollViewIsDragging: Bool = false {
        didSet {
            print("scrollViewIsDragging", scrollViewIsDragging)
        }
    }

    @Published var scrollViewStartDraggingOffset: CGPoint = .zero {
        didSet {
            print("scrollViewStartDraggingOffset", scrollViewStartDraggingOffset)
        }
    }

    @Published var headerSize: CGFloat = 44
    @Published var contentOffset: CGPoint = .zero {
        didSet {
            print("contentOffset", contentOffset)
        }
    }

    private var keyboardCancellable: AnyCancellable?

    init() {
        bindKeyboard()
    }

    func onAppear() {
        updateToCurrentState()
    }

    func updateToCurrentState() {
        withAnimation(.easeOut) {
            visibleHeight = currentHeight()
        }
    }

    func updateToState(_ state: SheetState) {
//        guard self.state != state else { return }
        self.state = state

        withAnimation(.easeOut) {
            visibleHeight = currentHeight()
        }
    }

    /// For dragging
    func updateVisibleHeight(_ height: CGFloat) {
        withAnimation(.default) {
            self.visibleHeight = height
        }
    }

    func currentHeight() -> CGFloat {
        height(for: state)
    }

    func height(for state: BottomSearchableSheetStateObject.SheetState) -> CGFloat {
        print("proxy.safeAreaInsets ->>", geometryInfo.safeAreaInsets)
        print("proxy.size ->>", geometryInfo.size)

        switch state {
        case .bottom:
            return headerSize + geometryInfo.safeAreaInsets.bottom
        case .top:
            return geometryInfo.size.height + geometryInfo.safeAreaInsets.bottom
        }
    }

    // MARK: Gestures

    func updateSheetFor(predictedEndLocation: CGPoint) {
        let centerLine = geometryInfo.size.height / 2
        // If the ended location below the center line
        if predictedEndLocation.y > centerLine {
            updateToState(.bottom)
        } else {
            updateToState(.top)
        }
    }

    func headerDragGesture(onChanged value: DragGesture.Value) {
        let locationChange = value.startLocation.y - value.location.y
        UIApplication.shared.keyWindow?.endEditing(true)
        withAnimation(.interactiveSpring()) {
            var heightChange = value.translation.height
            if locationChange > 0 {
                heightChange /= 3
            }

            let newHeight = currentHeight() - heightChange
            updateVisibleHeight(newHeight)
        }
    }

    func headerDragGesture(onEnded value: DragGesture.Value) {
        updateSheetFor(predictedEndLocation: value.predictedEndLocation)
    }

    func contentDragGesture(onChanged value: UIPanGestureRecognizer.Value) {
        UIApplication.shared.keyWindow?.endEditing(true)

//        print("onChanged", value)
//        print("value.translation.height", value.translation.height)
        var translationChange = value.translation.height
        if scrollViewStartDraggingOffset.y <= .zero, translationChange > 0 {
            if !scrollViewIsDragging {
                scrollViewIsDragging = true
            }

//            if translationChange < 0 {
//                translationChange /= 10
//            }

            print("value.translation.height", translationChange)
            let newHeight = currentHeight() - translationChange
            updateVisibleHeight(newHeight)
        }
    }

    func contentDragGesture(onEnded value: UIPanGestureRecognizer.Value) {
        // If scrollView stay in the top
        if scrollViewStartDraggingOffset.y <= .zero {
            // The user made a quick enough swipe to hide sheet
            let isHighVelocity = value.velocity.y > geometryInfo.size.height

            // The user stop swipe below critical line
            let isStoppedBelowCenter = visibleHeight < height(for: .top) * 0.5

            if isHighVelocity || isStoppedBelowCenter {
                updateToState(.bottom)
            } else {
                updateToState(.top)
            }
        }

        if scrollViewIsDragging {
            scrollViewIsDragging = false
        }

        // Save the `contentOffset` for check it in the `onChange` method
        scrollViewStartDraggingOffset = contentOffset
    }

    private func bindKeyboard() {
        keyboardCancellable = Publishers.Merge(
            NotificationCenter
                .default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            NotificationCenter
                .default
                .publisher(for: UIResponder.keyboardDidHideNotification)
                .map { _ in false }
        )
        .sink { [weak self] isKeyboardVisible in
            print("Is keyboard visible? ", isKeyboardVisible)
            if isKeyboardVisible {
                self?.state = .top
            }
        }
    }
}

extension BottomSearchableSheetStateObject: ScrollViewRepresentableDelegate {
    func contentOffsetDidChanged(contentOffset: CGPoint) {
        self.contentOffset = contentOffset
    }

    func gesture(onChanged value: UIPanGestureRecognizer.Value) {
        contentDragGesture(onChanged: value)
    }

    func gesture(onEnded value: UIPanGestureRecognizer.Value) {
        contentDragGesture(onEnded: value)
    }
}

extension BottomSearchableSheetStateObject {
    enum SheetState: String, Hashable {
        case top
        case bottom
    }
}

// MARK: - GeometryReaderPreferenceKey

extension BottomSearchableSheetStateObject {
    struct GeometryReaderPreferenceKey: PreferenceKey {
        typealias Value = GeometryInfo
        static var defaultValue: Value { .init() }

        static func reduce(value: inout Value, nextValue: () -> Value) {}
    }

    struct GeometryInfo: Equatable {
        let size: CGSize
        let safeAreaInsets: EdgeInsets

        init(size: CGSize = .zero, safeAreaInsets: EdgeInsets = .init()) {
            self.size = size
            self.safeAreaInsets = safeAreaInsets
        }
    }
}

struct BottomSearchableSheet<Content: View>: View {
    @Binding var searchText: String
    @ObservedObject var coordinator: BottomSearchableSheetCoordinator
    @ObservedObject var stateObject: BottomSearchableSheetStateObject

    @ViewBuilder let content: () -> Content

    private let handHeight: CGFloat = 20
    private let indicatorSize = CGSize(width: 32, height: 4)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(min(stateObject.percent, 0.4))
                    .ignoresSafeArea(.all)

                sheet(proxy: proxy)

                NavHolder()
                    .bottomSheet(item: $coordinator.bottomSheet) {
                        BottomSheetContainer_Previews.BottomSheetView(viewModel: $0)
                    }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height + proxy.safeAreaInsets.vertical,
                alignment: .bottom
            )
//            .border(Color.orange, width: 3)
            .ignoresSafeArea(.all, edges: .all)
            .onAppear {
                stateObject.onAppear()
            }
            .preference(
                key: BottomSearchableSheetStateObject.GeometryReaderPreferenceKey.self,
                value: .init(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            )
            .onPreferenceChange(BottomSearchableSheetStateObject.GeometryReaderPreferenceKey.self) { newValue in
                stateObject.geometryInfo = newValue
                print("onChange.size", newValue.size)
                print("onChange.safeAreaInsets", newValue.safeAreaInsets)
            }
        }
    }

    private func sheet(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Color.white

            VStack(spacing: 8) {
                headerView(proxy: proxy)

                scrollView(proxy: proxy)
            }
        }
        .frame(height: stateObject.visibleHeight, alignment: .bottom)
        .cornerRadius(28, corners: [.topLeft, .topRight])
//        .border(Color.orange, width: 3)
    }

    private func headerView(proxy: GeometryProxy) -> some View {
        VStack(spacing: .zero) {
            indicator

            TextField("Placeholder", text: $searchText)
                .frame(height: 46)
                .padding(.horizontal)
                .background(Color.secondary.opacity(0.4))
                .cornerRadius(14)
                .padding(.horizontal)
//                .padding(.vertical, 8)
        }
        .readGeometry(\.size.height, bindTo: $stateObject.headerSize)
        .gesture(dragGesture(proxy: proxy))
    }

    private var indicator: some View {
        ZStack(alignment: .center) {
            Capsule(style: .continuous)
                .fill(Color.gray)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
        }
        .frame(maxWidth: .infinity)
        .frame(height: handHeight)
    }

    private func scrollView(proxy: GeometryProxy) -> some View {
        ScrollViewRepresentable(delegate: stateObject) {
            content()
                .background(Color.green.opacity(0.2))
        }
        .isScrollDisabled(stateObject.scrollViewIsDragging)
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                stateObject.headerDragGesture(onChanged: value)
            }
            .onEnded { value in
                stateObject.headerDragGesture(onEnded: value)
            }
    }
}

public struct BottomSearchableSheet_Preview: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }

    public struct ContentView: View {
        private var coordinator = BottomSearchableSheetCoordinator()
        @ObservedObject
        private var stateObject = BottomSearchableSheetStateObject()

        @State private var data: [String]
        @State private var text: String = ""

        public init() {
            data = [
                "8720887669",
                "6039443653",
                "9850878178",
                "2523434461",
                "3225165235",
                "1571481152",
                "1419738515",
                "1791877061",
                "5591228645",
                "7682196099",
                "2348297778",
                "1844539876",
                "5201470631",
                "5056640801",
                "5362434881",
                "4262364184",
                "3147960099",
                "4494423305",
                "0400480229",
                "8439651677",
                "3395831241",
                "8836341113",
                "1716823902",
                "8318130334",
                "5781367105",
                "2350841586",
                "0766309218",
                "9862777806",
                "2237740770",
                "7678295553",
                "1360253958",
                "5927156193",
                "0163843915",
                "1203085116",
                "8007135186",
                "7245306292",
                "5962971496",
                "7859817739",
                "5876523700",
                "0203416494",
                "3030361471",
                "1304408513",
                "3486010173",
                "9205641047",
                "3058042191",
                "2301414836",
                "6824028479",
                "6495209954",
                "2427762150",
                "2973843019",
            ]
        }

        public var body: some View {
            ZStack(alignment: .bottom) {
                Color.blue.brightness(0.2)
                    .cornerRadius(14)
                    .scaleEffect(min(1, abs(1 - stateObject.percent / 30)), anchor: .bottom)
                    .edgesIgnoringSafeArea(.all)

                BottomSearchableSheet(
                    searchText: $text,
                    coordinator: coordinator,
                    stateObject: stateObject
                ) {
                    LazyVStack(spacing: .zero) {
                        ForEach(data.filter { text.isEmpty ? true : $0.contains(text.lowercased()) }, id: \.self) { index in
                            Button {
                                coordinator.toggleItem()
                                data[data.firstIndex(of: index)!] += "-1"
                            } label: {
                                Text(index)
                                    .font(.title3)
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.all)
                            }

                            Color.black
                                .opacity(0.2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}
