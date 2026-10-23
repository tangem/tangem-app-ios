#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct ModalStatusShowcase: View {
    @State private var appearance: AppearanceKind = .success
    @State private var titleStyle: ModalStatusTitleStyle = .status
    @State private var assetSlot: AssetSlotKind = .defaultIcon
    @State private var showsExtraBottom = false
    @State private var details: DetailsKind = .none
    @State private var showsSecondaryAction = false
    @State private var showsDragIndicator = true
    @State private var actionTaps = 0
    @State private var isPresented = false

    var body: some View {
        DSShowcase("ModalStatus") { controls in
            controls.picker("Asset slot", $assetSlot)
            if assetSlot == .defaultIcon {
                controls.picker("Appearance", $appearance)
            }
            controls.picker("Title style", $titleStyle)
            controls.toggle("Extra bottom", $showsExtraBottom)
            controls.picker("Details", $details)
            controls.toggle("Secondary action", $showsSecondaryAction)
            controls.toggle("Drag indicator", $showsDragIndicator)
            controls.readout("Action taps", "\(actionTaps)")
            controls.action("Present modal") { isPresented = true }
            controls.note("Present modal hosts the stage in the DS3 Modal, whose navigation bar owns the close button.")
        } stage: {
            sample { actionTaps += 1 }
                .modalStatus(isPresented: $isPresented, dragIndicator: showsDragIndicator ? .visible : .hidden) {
                    sample { isPresented = false }
                }
        } matrix: {
            DSShowcaseGroup("Variant") {
                DSShowcaseMatrix(rows: AppearanceKind.allCases) { kind in
                    let sample = Sample(kind)

                    ModalStatus(kind.appearance, title: sample.title, description: sample.description)
                        .frame(width: 360)
                }
            }

            DSShowcaseGroup("Status Title") {
                DSShowcaseMatrix(rows: ModalStatusTitleStyle.allCases) { style in
                    let sample = Sample(.neutral)

                    ModalStatus(.neutral(Sample.neutralGlyph), title: sample.title, description: sample.description)
                        .titleStyle(style)
                        .frame(width: 360)
                }
            }

            DSShowcaseGroup("Slots") {
                DSShowcaseMatrix(rows: AppearanceKind.allCases) { kind in
                    let sample = Sample(kind)

                    ModalStatus(kind.appearance, title: sample.title, description: sample.description)
                        .extraBottom { extraBottomBadge }
                        .details { detailsRows }
                        .frame(width: 360)
                }
            }
        }
    }
}

// MARK: - Composed content

private extension ModalStatusShowcase {
    // MARK: - View properties

    @ViewBuilder
    func sample(onAction: @escaping () -> Void) -> some View {
        switch assetSlot {
        case .defaultIcon:
            let sample = Sample(appearance)
            let status = ModalStatus(appearance.appearance, title: sample.title, description: sample.description)

            composed(configured(status, sample: sample, onAction: onAction))
        case .transaction:
            let sample = Sample(.neutral)
            let status = ModalStatus(title: sample.title, description: sample.description) {
                Avatar(.transaction(.send, status: .progress), size: .size72)
            }

            composed(configured(status, sample: sample, onAction: onAction))
        }
    }

    func configured<Asset: View>(
        _ status: ModalStatus<Asset, EmptyView, EmptyView>,
        sample: Sample,
        onAction: @escaping () -> Void
    ) -> ModalStatus<Asset, EmptyView, EmptyView> {
        let primary = TangemUI.Button(label: sample.primaryTitle, accessibilityLabel: nil, action: onAction)
        let secondary = showsSecondaryAction
            ? TangemUI.Button(label: sample.secondaryTitle, accessibilityLabel: nil, action: onAction)
            : nil

        return status
            .titleStyle(titleStyle)
            .actions(primary: primary, secondary: secondary)
    }

    @ViewBuilder
    func composed<Asset: View>(_ status: ModalStatus<Asset, EmptyView, EmptyView>) -> some View {
        if showsExtraBottom {
            withDetails(status.extraBottom { extraBottomBadge })
        } else {
            withDetails(status)
        }
    }

    @ViewBuilder
    func withDetails<Asset: View, ExtraBottom: View>(_ status: ModalStatus<Asset, ExtraBottom, EmptyView>) -> some View {
        switch details {
        case .none:
            status
        case .rows:
            status.details { detailsRows }
        case .customAndRows:
            status.details {
                completedRow
                feeRow
            }
        }
    }

    var extraBottomBadge: some View {
        Badge(label: "Your bet: Yes", accessibilityLabel: nil)
            .appearance(.success)
    }

    var detailsRows: some View {
        VStack(spacing: 0) {
            Row(title: "Qty of tokens", value: "248.50")
                .showDivider()
            Row(title: "Price", value: "$0.81")
                .showDivider()
            Row(title: "Fee", value: "$5.00")
                .showDivider()
            Row(title: "Notional gross", value: "$166.50")
        }
    }

    var completedRow: some View {
        HStack {
            Text("Completed")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Spacer()

            DesignSystem.Icons.Success.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconStatusSuccess)
        }
        .padding(.leading, 16)
        .padding([.trailing, .vertical], 12)
    }

    var feeRow: some View {
        Row(title: "Network fee", value: "$5.00")
    }
}

// MARK: - Controls

private extension ModalStatusShowcase {
    enum AppearanceKind: CaseIterable {
        case neutral
        case success
        case error
        case warning
        case info

        var appearance: ModalStatusAppearance {
            switch self {
            case .neutral: .neutral(Sample.neutralGlyph)
            case .success: .success
            case .error: .error
            case .warning: .warning
            case .info: .info
            }
        }
    }

    enum AssetSlotKind: CaseIterable {
        case defaultIcon
        case transaction
    }

    enum DetailsKind: CaseIterable {
        case none
        case rows
        case customAndRows
    }
}

// MARK: - Sample data

private extension ModalStatusShowcase {
    struct Sample {
        static let neutralGlyph = DesignSystem.Icons.Lightning.regular28

        let title: String
        let description: String
        let primaryTitle: String
        let secondaryTitle: String

        init(_ kind: AppearanceKind) {
            switch kind {
            case .neutral:
                title = "-$166.84"
                description = "Will Ethereum reach $5,000 before Sep 30?"
                primaryTitle = "Go to Predict"
                secondaryTitle = "Share"
            case .success:
                title = "Card sold for $12.75"
                description = "USDC has landed on your Packs account and is ready for the next pack"
                primaryTitle = "Got it"
                secondaryTitle = "Open another pack"
            case .error:
                title = "Virtual account not available"
                description = "Unfortunately, virtual accounts are not available in your country yet. "
                    + "We're working on expanding to more regions"
                primaryTitle = "Hide from home screen"
                secondaryTitle = "Learn more"
            case .warning:
                title = "An error occurred"
                description = "Something went wrong, but you still have an unopened pack. "
                    + "You can open it right now or stay here and continue"
                primaryTitle = "Continue"
                secondaryTitle = "Open pack"
            case .info:
                title = "KYC in progress"
                description = "Use the buttons below to view your current KYC status or cancel it"
                primaryTitle = "Got it"
                secondaryTitle = "Cancel KYC"
            }
        }
    }
}
#endif
