import SwiftUI
import AppKit
import Lottie
import IOKit.ps

private let ghostAccent = Color(red: 0.831, green: 0.984, blue: 0.451)
private let ghostTextPri = Color(red: 0.831, green: 0.831, blue: 0.831)
private let ghostTextSec = Color(red: 0.659, green: 0.659, blue: 0.659)
private let ghostTextTer = Color(red: 0.561, green: 0.561, blue: 0.561)
private let ghostTextMut = Color(red: 0.459, green: 0.459, blue: 0.459)
private let ghostAmber = Color(red: 0.961, green: 0.620, blue: 0.043)
private let ghostBgElev = Color(red: 0.161, green: 0.169, blue: 0.157)

struct NotchShellView: View {
    @ObservedObject var viewModel: NotchViewModel

    private var screen: NSScreen { NSScreen.main ?? NSScreen.screens[0] }
    private var notchW: CGFloat { screen.notchWidth }
    private var notchH: CGFloat { screen.notchHeight }
    private var expanded: Bool { viewModel.isExpanded }
    private var peeking: Bool { viewModel.peekVisible && !expanded }
    @State private var peekHovered = false

    private var shapeWidth: CGFloat {
        if peeking && peekHovered { return notchW + 200 }
        if peeking { return notchW }
        if !expanded { return notchW }
        return viewModel.isInTaskOrChat ? 460 : 440
    }

    private var shapeHeight: CGFloat {
        if peeking { return notchH + 32 }
        if !expanded { return notchH }
        switch viewModel.viewState {
        case .overview: return notchH + 210
        case .taskList: return notchH + 240
        case .agentChat: return notchH + 300
        }
    }

    private var bottomRadius: CGFloat {
        if peeking { return 14 }
        return expanded ? 22 : 10
    }

    var body: some View {
        ZStack(alignment: .top) {
            notchShape

            if expanded {
                expandedTopBar
                    .transition(.opacity)

                if viewModel.showSettings {
                    SettingsPanel(viewModel: viewModel)
                        .padding(.top, notchH + 1)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .frame(width: shapeWidth, alignment: .top)
                        .transition(.opacity)
                } else {
                    NotchContentView(viewModel: viewModel)
                        .padding(.top, notchH + 1)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .frame(width: shapeWidth, alignment: .top)
                }
            } else if peeking {
                peekView
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .frame(width: shapeWidth, height: shapeHeight)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: bottomRadius,
                bottomTrailingRadius: bottomRadius,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .onHover { hovering in
            viewModel.mouseInContent = hovering
            if peeking {
                withAnimation(.smooth(duration: 0.35)) {
                    peekHovered = hovering
                }
            } else {
                peekHovered = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.snappy(duration: 0.4), value: expanded)
        .animation(.smooth(duration: 0.6), value: peeking)
        .animation(.smooth(duration: 0.35), value: peekHovered)
        .animation(.snappy(duration: 0.35), value: viewModel.viewState)
        .animation(.snappy(duration: 0.3), value: viewModel.showSettings)
    }

    private var notchShape: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(.black)
        .shadow(
            color: .black.opacity(expanded ? 0.55 : (peeking ? 0.3 : 0)),
            radius: expanded ? 30 : (peeking ? 15 : 0),
            y: expanded ? 8 : (peeking ? 4 : 0)
        )
    }

    // MARK: - Peek suggestion view

    private var peekView: some View {
        HStack(spacing: 8) {
            LottieView(animation: .named("ghost_twirl", bundle: .module))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .animationSpeed(0.8)
                .frame(width: 22, height: 22)

            if let suggestion = viewModel.peekSuggestion {
                Text(suggestion)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ghostTextPri)
                    .lineLimit(peekHovered ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: peekHovered)
                    .transition(.opacity.animation(.easeIn(duration: 0.4).delay(0.2)))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 32, alignment: .leading)
        .offset(y: notchH)
    }

    // MARK: - Expanded top bar: tabs (left) + battery (right)

    private var expandedTopBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                tabButton(
                    icon: "house.fill",
                    isActive: viewModel.viewState == .overview
                ) {
                    withAnimation(.snappy(duration: 0.35)) {
                        viewModel.viewState = .overview
                    }
                }

                tabButton(
                    icon: "person.2.fill",
                    isActive: viewModel.isInTaskOrChat
                ) {
                    withAnimation(.snappy(duration: 0.35)) {
                        viewModel.viewState = .taskList
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Color.clear.frame(width: notchW + 16)

            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.snappy(duration: 0.25)) {
                        viewModel.showSettings.toggle()
                    }
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(viewModel.showSettings ? ghostAccent : ghostTextMut)
                }
                .buttonStyle(.plain)

                BatteryView()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(width: shapeWidth, height: notchH)
    }

    private func tabButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? ghostAccent : ghostTextMut)
                .frame(width: 30, height: 20)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isActive ? ghostAccent.opacity(0.15) : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Battery View

struct BatteryView: View {
    @State private var level: Int = 0
    @State private var isCharging: Bool = false
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            Text("\(level)%")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(ghostTextSec)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(ghostTextMut, lineWidth: 0.8)
                    .frame(width: 18, height: 9)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(batteryColor)
                    .frame(width: max(CGFloat(level) / 100.0 * 15, 2), height: 6)
                    .padding(.leading, 1.5)

                RoundedRectangle(cornerRadius: 0.5)
                    .fill(ghostTextMut)
                    .frame(width: 1.5, height: 4)
                    .offset(x: 18.5)
            }

            if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 7))
                    .foregroundColor(ghostAccent)
            }
        }
        .onAppear {
            updateBattery()
            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                DispatchQueue.main.async { updateBattery() }
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private var batteryColor: Color {
        if isCharging { return ghostAccent }
        if level <= 20 { return Color(red: 0.937, green: 0.267, blue: 0.267) }
        return ghostTextMut
    }

    private func updateBattery() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] else { continue }
            if let capacity = desc[kIOPSCurrentCapacityKey] as? Int {
                level = capacity
            }
            if let charging = desc[kIOPSIsChargingKey] as? Bool {
                isCharging = charging
            }
        }
    }
}

// MARK: - Settings Panel

struct SettingsPanel: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SETTINGS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(ghostTextMut)
                .tracking(1)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Peek interval")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ghostTextPri)

                    Spacer()

                    Text("\(Int(viewModel.peekInterval))s")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(ghostAccent)
                }

                Slider(value: Binding(
                    get: { viewModel.peekInterval },
                    set: { viewModel.updatePeekInterval($0) }
                ), in: 3...30, step: 1)
                .tint(ghostAccent)

                HStack {
                    Text("3s")
                        .font(.system(size: 8))
                        .foregroundColor(ghostTextMut)
                    Spacer()
                    Text("30s")
                        .font(.system(size: 8))
                        .foregroundColor(ghostTextMut)
                }
            }
            .padding(10)
            .background(ghostBgElev)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
