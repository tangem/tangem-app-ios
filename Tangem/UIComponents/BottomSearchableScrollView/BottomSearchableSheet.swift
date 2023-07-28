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

    init() {}

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

extension BottomSearchableSheetStateObject {
    enum SheetState: String, Hashable {
        case top
        case bottom
    }
}

struct BottomSearchableSheet<Content: View>: View {
    @Binding var searchText: String
    @ObservedObject var coordinator: BottomSearchableSheetCoordinator
    @ObservedObject var stateObject: BottomSearchableSheetStateObject
    @ViewBuilder let content: () -> Content

    private let scrollViewCoordinateNamespace = UUID().uuidString

//    init(
//        coordinator: BottomSearchableSheetCoordinator,
//        searchText: String,
//        percent: CGFloat,
//        content: @escaping () -> Content
//    ) {
//        self.coordinator = coordinator
//        self.searchText = searchText
//        self.percent = percent
//        self.content = content
//    }

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
                updateToState(proxy: proxy)
            }
            .onChange(of: stateObject.state, perform: { _ in
                updateToState(proxy: proxy)
            })
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
//        .background(Color.purple.opacity(0.5))
    }

    private var axes: Axis.Set {
        return stateObject.scrollViewIsDragging ? [] : .vertical
    }

    private func scrollView(proxy: GeometryProxy) -> some View {
        ScrollView(axes, showsIndicators: false) {
            VStack(spacing: .zero) {
                offsetReader

                content()
//                    .background(Color.green.opacity(0.2))
            }
            .overlay(contentDragGesture(proxy: proxy))
        }
        .coordinateSpace(name: scrollViewCoordinateNamespace)
        .onPreferenceChange(OffsetPreferenceKey.self) { point in
            stateObject.contentOffset = point
        }
    }

    private func testGesture() -> some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .global)
            .onChanged { value in
                print("onChanged", value.translation.height)
            }
            .onEnded { value in
                print("onEnded", value.translation.height)
            }
    }

    private func contentDragGesture(proxy: GeometryProxy) -> ClearDragGestureView {
        ClearDragGestureView(onChanged: { value in
            contentDragGesture(onChanged: value, proxy: proxy)
        }, onEnded: { value in
            contentDragGesture(onEnded: value, proxy: proxy)
        })
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
//                if !stateObject.isDragging {
//                    stateObject.isDragging = true
//                }

//                let dragValue = value.translation.height - previousDragTranslation.height
                let locationChange = value.startLocation.y - value.location.y
//                print("locationChange", locationChange)
//                print("gesture.location ->>", value.location)
//                print("gesture.translation ->>", value.translation)
//                print("gesture.startLocation ->>", value.startLocation)
                UIApplication.shared.keyWindow?.endEditing(true)
                withAnimation(.interactiveSpring()) {
                    var heightChange = value.translation.height
                    if locationChange > 0 {
                        heightChange /= 3
                    }

                    let newHeight = currentHeight(proxy: proxy) - heightChange
                    stateObject.visibleHeight = newHeight
                }
            }
            .onEnded { value in
//                stateObject.previousDragTranslation = .zero
//                stateObject.isDragging = false
//                print("value.predictedEndLocation ->>", value.predictedEndLocation)
//                print("value.location ->>", value.location)
//                print("value.translation.height ->>", value.translation.height)

                updateSheetFor(predictedEndLocation: value.predictedEndLocation, proxy: proxy)
            }
    }

    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(scrollViewCoordinateNamespace)).origin
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Methods

extension BottomSearchableSheet {
    func updateSheetFor(
        predictedEndLocation: CGPoint,
        proxy: GeometryProxy
    ) {
        let centerLine = proxy.size.height / 2
        // If the ended location below the center line
        if predictedEndLocation.y > centerLine {
            stateObject.state = .bottom
        } else {
            stateObject.state = .top
        }

        updateToState(proxy: proxy)
    }

    func height(for state: BottomSearchableSheetStateObject.SheetState, proxy: GeometryProxy) -> CGFloat {
        print("proxy.safeAreaInsets ->>", proxy.safeAreaInsets)
        print("proxy.size ->>", proxy.size)
        print("proxy.size.frame ->>", proxy.frame(in: .global).size)

        switch state {
        case .bottom:
            return stateObject.headerSize + 12 // proxy.safeAreaInsets.bottom
//        case .middle:
//            return proxy.size.height / 2 + proxy.safeAreaInsets.bottom
        case .top:
            return proxy.size.height + proxy.safeAreaInsets.bottom
        }
    }

    func currentHeight(proxy: GeometryProxy) -> CGFloat {
        height(for: stateObject.state, proxy: proxy)
    }

    func updateToState(proxy: GeometryProxy) {
        withAnimation(.easeOut) {
            stateObject.visibleHeight = currentHeight(proxy: proxy)
        }
    }

    func contentDragGesture(onChanged value: ClearDragGestureView.Value, proxy: GeometryProxy) {
        UIApplication.shared.keyWindow?.endEditing(true)

//        print("onChanged", value)
//        print("value.translation.height", value.translation.height)
        var translationChange = value.translation.height
        if stateObject.scrollViewStartDraggingOffset.y >= .zero, translationChange > 0 {
            if !stateObject.scrollViewIsDragging {
                stateObject.scrollViewIsDragging = true
            }

            if translationChange < 0 {
                translationChange /= 10
            }

            print("value.translation.height", translationChange)
            withAnimation(.interactiveSpring()) {
                stateObject.visibleHeight = currentHeight(proxy: proxy) - translationChange
            }
        }
    }

    func contentDragGesture(onEnded value: ClearDragGestureView.Value, proxy: GeometryProxy) {
        if stateObject.scrollViewStartDraggingOffset.y >= .zero {
            if stateObject.visibleHeight < height(for: .top, proxy: proxy) * 0.5 {
                stateObject.state = .bottom
            }
            updateToState(proxy: proxy)
        }

        if stateObject.scrollViewIsDragging {
            stateObject.scrollViewIsDragging = false
        }
        stateObject.scrollViewStartDraggingOffset = stateObject.contentOffset
    }
}

public struct BottomSearchableSheet_Preview: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }

    public struct ContentView: View {
        let data: [String]
        private var coordinator = BottomSearchableSheetCoordinator()
        private var stateObject = BottomSearchableSheetStateObject()
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

extension View {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardDidHideNotification)
                    .map { _ in false }
            )
//      .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
