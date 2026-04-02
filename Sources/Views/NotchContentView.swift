import SwiftUI
import Lottie

// Ghost dark mode palette
private let ghostAccentGreen = Color(red: 0.831, green: 0.984, blue: 0.451)
private let ghostTextPrimary = Color(red: 0.831, green: 0.831, blue: 0.831)
private let ghostTextSecondary = Color(red: 0.659, green: 0.659, blue: 0.659)
private let ghostTextTertiary = Color(red: 0.561, green: 0.561, blue: 0.561)
private let ghostTextMuted = Color(red: 0.459, green: 0.459, blue: 0.459)
private let ghostBgElevated = Color(red: 0.161, green: 0.169, blue: 0.157)
private let ghostBorder = Color(red: 0.224, green: 0.231, blue: 0.220)
private let ghostBorderStrong = Color(red: 0.310, green: 0.318, blue: 0.306)
private let ghostSuccessGreen = Color(red: 0.133, green: 0.773, blue: 0.369)
private let ghostErrorRed = Color(red: 0.937, green: 0.267, blue: 0.267)
private let ghostWarningAmber = Color(red: 0.961, green: 0.620, blue: 0.043)
private let ghostDarkGray = Color(red: 0.471, green: 0.463, blue: 0.451)
private let ghostTextOnAccent = Color(red: 0.110, green: 0.098, blue: 0.090)

struct NotchContentView: View {
    @ObservedObject var viewModel: NotchViewModel

    private var isExpanded: Bool {
        viewModel.viewState != .overview
    }

    private var leftWidth: CGFloat {
        isExpanded ? 0 : 185
    }

    private var approvalTasks: [SubagentTask] {
        Array(viewModel.tasks.filter { $0.status == .awaitingApproval }.prefix(2))
    }

    private var approvalIds: Set<String> {
        Set(approvalTasks.map { $0.id })
    }

    private var rightColumnTasks: [SubagentTask] {
        viewModel.tasks.filter { !approvalIds.contains($0.id) && $0.status != .completed }
    }

    private var completedTasks: [SubagentTask] {
        viewModel.tasks.filter { $0.status == .completed }
    }

    var body: some View {
        HStack(spacing: 0) {
            leftColumn
                .frame(width: leftWidth)
                .opacity(isExpanded ? 0 : 1)
                .clipped()

            dividerBar
                .opacity(isExpanded ? 0 : 1)
                .scaleEffect(y: isExpanded ? 0.3 : 1)
                .frame(width: isExpanded ? 0 : nil)
                .clipped()

            mainColumn
        }
        .animation(.snappy(duration: 0.35), value: isExpanded)
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(viewModel.timeString)
                            .font(.system(size: 30, weight: .thin, design: .rounded))
                            .foregroundColor(ghostTextPrimary)
                        Text(viewModel.periodString)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(ghostTextMuted)
                    }

                    Text(viewModel.dateString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ghostTextTertiary)
                }

                Spacer()

                GhostIconView()
                    .frame(width: 34, height: 26)
                    .padding(.top, 6)
                    .opacity(0.85)
            }

            Spacer().frame(height: 2)

            if approvalTasks.isEmpty {
                MiniCalendarView(compact: false)
            } else {
                MiniCalendarView(compact: true)
                Spacer().frame(height: 4)
                approvalCards
            }
        }
        .padding(.trailing, 8)
    }

    // MARK: - Approval cards on left

    private var approvalCards: some View {
        VStack(spacing: 4) {
            ForEach(approvalTasks) { task in
                Button(action: {
                    withAnimation(.snappy(duration: 0.35)) {
                        viewModel.viewState = .agentChat(task.id)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(ghostWarningAmber)

                        Text(task.description ?? task.task)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(ghostTextSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ghostWarningAmber.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ghostWarningAmber.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Divider

    private var dividerBar: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(ghostBorder)
            .frame(width: 1)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
    }

    // MARK: - Main Column

    @ViewBuilder
    private var mainColumn: some View {
        switch viewModel.viewState {
        case .overview:
            overviewRightColumn
        case .taskList:
            agentsColumn(isCompact: false)
        case .agentChat(let taskId):
            AgentChatView(viewModel: viewModel, taskId: taskId)
        }
    }

    // MARK: - Overview right column (active agents + recently completed bar)

    private var overviewRightColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                GhostLottieView()
                    .frame(width: 16, height: 16)

                Text("AGENTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ghostTextMuted)
                    .tracking(1)

                Spacer()

                HStack(spacing: 8) {
                    if viewModel.delegatedCount > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(ghostWarningAmber).frame(width: 5, height: 5)
                            Text("\(viewModel.delegatedCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ghostWarningAmber)
                        }
                    }
                    if viewModel.approvalCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(ghostWarningAmber)
                            Text("\(viewModel.approvalCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ghostWarningAmber)
                        }
                    }
                    if viewModel.finishedCount > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(ghostSuccessGreen).frame(width: 5, height: 5)
                            Text("\(viewModel.finishedCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ghostSuccessGreen)
                        }
                    }
                }
            }

            // Active/approval tasks
            VStack(spacing: 4) {
                ForEach(rightColumnTasks) { task in
                    AgentRow(
                        task: task,
                        isCompact: true,
                        activityText: viewModel.activityText(for: task)
                    ) {
                        withAnimation(.snappy(duration: 0.35)) {
                            viewModel.viewState = .taskList
                        }
                    }
                }
            }

            // Recently completed horizontal bar
            if !completedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(ghostBorder)
                        .frame(height: 0.5)

                    Text("RECENTLY COMPLETED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ghostTextMuted)
                        .tracking(0.8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(completedTasks) { task in
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(ghostSuccessGreen)
                                    Text(task.description ?? task.task)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(ghostTextTertiary)
                                        .lineLimit(1)
                                    Text(task.durationString)
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundColor(ghostSuccessGreen.opacity(0.7))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ghostSuccessGreen.opacity(0.06))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(ghostSuccessGreen.opacity(0.12), lineWidth: 0.5)
                                )
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Full agents column (task list mode)

    private func agentsColumn(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                GhostLottieView()
                    .frame(width: 16, height: 16)

                Text("AGENTS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ghostTextMuted)
                    .tracking(1)

                Spacer()

                HStack(spacing: 8) {
                    if viewModel.delegatedCount > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(ghostWarningAmber).frame(width: 5, height: 5)
                            Text("\(viewModel.delegatedCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ghostWarningAmber)
                        }
                    }
                    if viewModel.approvalCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(ghostWarningAmber)
                            Text("\(viewModel.approvalCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ghostWarningAmber)
                        }
                    }
                    if viewModel.finishedCount > 0 {
                        HStack(spacing: 3) {
                            Circle().fill(ghostSuccessGreen).frame(width: 5, height: 5)
                            Text("\(viewModel.finishedCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ghostSuccessGreen)
                        }
                    }
                }
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(viewModel.tasks) { task in
                        AgentRow(
                            task: task,
                            isCompact: false,
                            activityText: viewModel.activityText(for: task)
                        ) {
                            withAnimation(.snappy(duration: 0.35)) {
                                viewModel.viewState = .agentChat(task.id)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Ghost Lottie Animations

struct GhostLottieView: View {
    var body: some View {
        LottieView(animation: .named("ghost_twirl", bundle: .module))
            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            .animationSpeed(0.8)
    }
}

struct GhostIconView: View {
    @State private var floating = false

    var body: some View {
        GhostShape()
            .fill(.white)
            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 0)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            .overlay(GhostEyes().fill(.black))
            .offset(x: floating ? 1.5 : -1.5, y: floating ? -4 : 1)
            .rotationEffect(.degrees(floating ? 2 : -2))
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: floating)
            .onAppear { floating = true }
    }
}

struct GhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let sx = w / 106.0
        let sy = h / 82.0

        var path = Path()
        path.move(to: CGPoint(x: 6.67 * sx, y: 70.47 * sy))
        path.addCurve(
            to: CGPoint(x: 52.72 * sx, y: 76 * sy),
            control1: CGPoint(x: 14.96 * sx, y: 73.24 * sy),
            control2: CGPoint(x: 39.82 * sx, y: 76 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 99.69 * sx, y: 36.39 * sy),
            control1: CGPoint(x: 75.75 * sx, y: 76 * sy),
            control2: CGPoint(x: 99.69 * sx, y: 64.03 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 70.22 * sx, y: 6 * sy),
            control1: CGPoint(x: 99.69 * sx, y: 11.53 * sy),
            control2: CGPoint(x: 80.35 * sx, y: 6 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 38.90 * sx, y: 33.63 * sy),
            control1: CGPoint(x: 53.64 * sx, y: 6 * sy),
            control2: CGPoint(x: 45.35 * sx, y: 17.05 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 6.67 * sx, y: 68.63 * sy),
            control1: CGPoint(x: 34.25 * sx, y: 45.59 * sy),
            control2: CGPoint(x: 26.93 * sx, y: 64.95 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 6.67 * sx, y: 70.47 * sy),
            control1: CGPoint(x: 5.76 * sx, y: 68.80 * sy),
            control2: CGPoint(x: 5.79 * sx, y: 70.18 * sy)
        )
        path.closeSubpath()
        return path
    }
}

struct GhostEyes: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let sx = w / 106.0
        let sy = h / 82.0

        var path = Path()
        path.addEllipse(in: CGRect(
            x: 58.25 * sx, y: 20.74 * sy,
            width: 9.21 * sx, height: 12.89 * sy
        ))
        path.addEllipse(in: CGRect(
            x: 82.19 * sx, y: 20.74 * sy,
            width: 9.21 * sx, height: 12.89 * sy
        ))
        return path
    }
}

// MARK: - Agent Row

struct AgentRow: View {
    let task: SubagentTask
    let isCompact: Bool
    let activityText: String
    let onTap: () -> Void

    @State private var isHovering = false

    private var statusColor: Color {
        switch task.status {
        case .running: return ghostWarningAmber
        case .completed: return ghostSuccessGreen
        case .awaitingApproval: return ghostWarningAmber
        case .failed: return ghostErrorRed
        case .cancelled: return ghostWarningAmber
        case .pending: return ghostDarkGray
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    if task.needsApproval {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(statusColor)
                    } else {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                            .shadow(color: task.isActive ? statusColor.opacity(0.5) : .clear, radius: 4)
                    }

                    Text(task.description ?? task.task)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ghostTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(task.durationString)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(ghostTextMuted)
                }

                if task.status == .running && (!isCompact || isHovering) {
                    ShimmerActivityView(text: activityText, color: ghostWarningAmber)
                        .padding(.leading, 14)
                        .padding(.top, 3)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, isCompact ? 5 : 7)
            .background(isCompact ? (isHovering ? ghostBgElevated : .clear) : ghostBgElevated.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(!isCompact ? ghostBorder.opacity(0.5) : .clear, lineWidth: 0.5)
            )
            .animation(.easeOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Shimmer Activity

struct ShimmerActivityView: View {
    let text: String
    let color: Color
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(color.opacity(0.5))
            .overlay(shimmerGradient)
            .onAppear { startShimmer() }
            .id(text)
    }

    private var shimmerGradient: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    .clear,
                    color.opacity(0.4),
                    .white.opacity(0.25),
                    color.opacity(0.4),
                    .clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.5)
            .offset(x: shimmerPhase * geo.size.width)
            .mask(
                Text(text)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            )
        }
    }

    private func startShimmer() {
        shimmerPhase = -0.5
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            shimmerPhase = 1.5
        }
    }
}

// MARK: - Mini Calendar

struct MiniCalendarView: View {
    let compact: Bool

    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    private var cal: Calendar { Calendar.current }
    private var today: Date { Date() }
    private var currentDay: Int { cal.component(.day, from: today) }

    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = compact ? "MMM" : "MMMM yyyy"
        return f.string(from: today)
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: today)?.count ?? 30
    }

    private var firstWeekday: Int {
        let comps = cal.dateComponents([.year, .month], from: today)
        guard let first = cal.date(from: comps) else { return 0 }
        return (cal.component(.weekday, from: first) - 1) % 7
    }

    var body: some View {
        if compact {
            compactCalendar
        } else {
            fullCalendar
        }
    }

    private var compactCalendar: some View {
        VStack(spacing: 2) {
            Text(monthName)
                .font(.system(size: 7, weight: .semibold))
                .foregroundColor(ghostTextMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 2) {
                        ForEach(1...daysInMonth, id: \.self) { day in
                            VStack(spacing: 1) {
                                Text(dayOfWeekLabel(day))
                                    .font(.system(size: 6, weight: .semibold, design: .rounded))
                                    .foregroundColor(ghostTextMuted)
                                Text("\(day)")
                                    .font(.system(size: 8, weight: day == currentDay ? .bold : .regular, design: .rounded))
                                    .foregroundColor(day == currentDay ? ghostTextOnAccent : (day < currentDay ? ghostTextMuted : ghostTextTertiary))
                            }
                            .frame(width: 16, height: 22)
                            .background {
                                if day == currentDay {
                                    RoundedRectangle(cornerRadius: 5).fill(ghostAccentGreen)
                                }
                            }
                            .id(day)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(max(currentDay - 2, 1), anchor: .leading)
                    }
                }
            }
        }
    }

    private func dayOfWeekLabel(_ day: Int) -> String {
        let comps = cal.dateComponents([.year, .month], from: today)
        var dc = comps
        dc.day = day
        guard let date = cal.date(from: dc) else { return "" }
        let weekday = cal.component(.weekday, from: date)
        return ["S","M","T","W","T","F","S"][weekday - 1]
    }

    private var fullCalendar: some View {
        VStack(spacing: 2) {
            Text(monthName)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(ghostTextMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundColor(ghostTextMuted)
                        .frame(width: 18, height: 10)
                }
            }

            let rows = buildCalendarDays()
            VStack(spacing: 1) {
                ForEach(0..<rows.count, id: \.self) { rowIdx in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            let day = rows[rowIdx][col]
                            if day > 0 {
                                Text("\(day)")
                                    .font(.system(size: 7, weight: day == currentDay ? .bold : .regular, design: .rounded))
                                    .foregroundColor(day == currentDay ? ghostTextOnAccent : (day < currentDay ? ghostTextMuted : ghostTextTertiary))
                                    .frame(width: 18, height: 13)
                                    .background {
                                        if day == currentDay {
                                            Circle().fill(ghostAccentGreen).frame(width: 14, height: 14)
                                        }
                                    }
                            } else {
                                Color.clear.frame(width: 18, height: 13)
                            }
                        }
                    }
                }
            }
        }
    }

    private func buildCalendarDays() -> [[Int]] {
        var rows: [[Int]] = []
        var row: [Int] = Array(repeating: 0, count: firstWeekday)
        for day in 1...daysInMonth {
            row.append(day)
            if row.count == 7 {
                rows.append(row)
                row = []
            }
        }
        if !row.isEmpty {
            while row.count < 7 { row.append(0) }
            rows.append(row)
        }
        return rows
    }
}
