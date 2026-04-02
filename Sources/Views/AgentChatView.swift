import SwiftUI
import Lottie

// MARK: - Tool Name Formatter

private func toolActionText(_ name: String) -> String {
    let map: [String: String] = [
        "gmail_search": "Searching Gmail",
        "gmail_read_email": "Reading email",
        "gmail_create_draft": "Creating draft",
        "gmail_send": "Sending email",
        "gmail_reply": "Replying to email",
        "notion_create_page": "Creating Notion page",
        "notion_append_block": "Updating Notion page",
        "notion_search": "Searching Notion",
        "linear_list_issues": "Fetching Linear issues",
        "linear_update_issue": "Updating Linear issue",
        "linear_add_comment": "Adding comment on Linear",
        "linear_create_issue": "Creating Linear issue",
        "calendar_list_events": "Checking calendar",
        "calendar_create_event": "Creating event",
        "slack_send_message": "Sending Slack message",
        "slack_search": "Searching Slack",
        "web_search": "Searching the web",
        "drive_search": "Searching Drive",
    ]
    return map[name] ?? name.replacingOccurrences(of: "_", with: " ").capitalized
}

private func toolCompletedText(_ name: String) -> String {
    let map: [String: String] = [
        "gmail_search": "Searched Gmail",
        "gmail_read_email": "Read email",
        "gmail_create_draft": "Created draft",
        "gmail_send": "Sent email",
        "gmail_reply": "Replied to email",
        "notion_create_page": "Created Notion page",
        "notion_append_block": "Updated Notion page",
        "notion_search": "Searched Notion",
        "linear_list_issues": "Fetched Linear issues",
        "linear_update_issue": "Updated Linear issue",
        "linear_add_comment": "Added comment on Linear",
        "linear_create_issue": "Created Linear issue",
        "calendar_list_events": "Checked calendar",
        "calendar_create_event": "Created event",
        "slack_send_message": "Sent Slack message",
        "slack_search": "Searched Slack",
        "web_search": "Searched the web",
        "drive_search": "Searched Drive",
    ]
    return map[name] ?? name.replacingOccurrences(of: "_", with: " ").capitalized
}

private func toolIcon(_ name: String) -> String {
    if name.hasPrefix("gmail") { return "envelope.fill" }
    if name.hasPrefix("notion") { return "doc.text.fill" }
    if name.hasPrefix("linear") { return "checklist" }
    if name.hasPrefix("calendar") { return "calendar" }
    if name.hasPrefix("slack") { return "number" }
    if name.hasPrefix("web") { return "globe" }
    if name.hasPrefix("drive") { return "folder.fill" }
    return "gearshape.fill"
}

private let ghostAccent = Color(red: 0.831, green: 0.984, blue: 0.451)
private let ghostTextPri = Color(red: 0.831, green: 0.831, blue: 0.831)
private let ghostTextSec = Color(red: 0.659, green: 0.659, blue: 0.659)
private let ghostTextTer = Color(red: 0.561, green: 0.561, blue: 0.561)
private let ghostTextMut = Color(red: 0.459, green: 0.459, blue: 0.459)
private let ghostBgElev = Color(red: 0.161, green: 0.169, blue: 0.157)
private let ghostBord = Color(red: 0.224, green: 0.231, blue: 0.220)
private let ghostSuccess = Color(red: 0.133, green: 0.773, blue: 0.369)
private let ghostError = Color(red: 0.937, green: 0.267, blue: 0.267)
private let ghostAmber = Color(red: 0.961, green: 0.620, blue: 0.043)
private let ghostGray = Color(red: 0.471, green: 0.463, blue: 0.451)
private let ghostOnAccent = Color(red: 0.110, green: 0.098, blue: 0.090)

// MARK: - Agent Chat View

struct AgentChatView: View {
    @ObservedObject var viewModel: NotchViewModel
    let taskId: String

    private var task: SubagentTask? {
        viewModel.taskById(taskId)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer().frame(height: 6)

            if let task = task {
                chatBody(task)
            }

            Spacer().frame(height: 6)
            inputBar
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.snappy(duration: 0.3)) {
                    viewModel.viewState = .taskList
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ghostTextTer)
            }
            .buttonStyle(.plain)

            if let task = task {
                Circle()
                    .fill(statusColor(for: task))
                    .frame(width: 7, height: 7)

                Text(task.description ?? task.task)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ghostTextPri)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Chat Body

    private func chatBody(_ task: SubagentTask) -> some View {
        let lastAgentMsgId = task.chatHistory.last(where: { $0.role == "agent" })?.id

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(task.chatHistory) { msg in
                    chatBubble(msg, isFinalResponse: msg.id == lastAgentMsgId)
                }

                if task.status == .running {
                    liveActivityBar(task)
                }
            }
        }
    }

    private func liveActivityBar(_ task: SubagentTask) -> some View {
        HStack(spacing: 8) {
            LottieView(animation: .named("ghost_twirl", bundle: .module))
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .animationSpeed(0.8)
                .frame(width: 16, height: 16)

            ShimmerActivityView(
                text: viewModel.activityText(for: task),
                color: ghostAmber
            )
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(ghostBgElev.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func chatBubble(_ msg: ChatMessage, isFinalResponse: Bool) -> some View {
        switch msg.role {
        case "agent":
            if isFinalResponse {
                Text(msg.content)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ghostTextPri)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                Text(msg.content)
                    .font(.system(size: 11))
                    .foregroundColor(ghostTextSec)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
            }

        case "tool":
            toolCallBubble(msg)

        case "draft":
            if let draft = msg.draftCard {
                DraftCardView(draft: draft)
            }

        default:
            EmptyView()
        }
    }

    private func toolCallBubble(_ msg: ChatMessage) -> some View {
        let name = msg.toolName ?? "tool"
        return HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(ghostSuccess)

            Image(systemName: toolIcon(name))
                .font(.system(size: 9))
                .foregroundColor(ghostTextMut)

            Text(toolCompletedText(name))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ghostTextSec)

            if !msg.content.isEmpty {
                Text("·")
                    .foregroundColor(ghostTextMut)
                Text(msg.content)
                    .font(.system(size: 10))
                    .foregroundColor(ghostTextTer)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 1)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text("Message agent...")
                .font(.system(size: 11))
                .foregroundColor(ghostTextMut)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(ghostTextMut.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ghostBgElev)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ghostBord, lineWidth: 0.5)
        )
    }

    private func statusColor(for task: SubagentTask) -> Color {
        switch task.status {
        case .running: return ghostAmber
        case .completed: return ghostSuccess
        case .awaitingApproval: return ghostAmber
        case .failed: return ghostError
        case .cancelled: return ghostAmber
        case .pending: return ghostGray
        }
    }
}

// MARK: - Draft Card

struct DraftCardView: View {
    let draft: DraftCard

    private var icon: String {
        switch draft.type {
        case "gmail_draft": return "envelope.fill"
        case "slack_message": return "number"
        default: return "doc.fill"
        }
    }

    private var typeLabel: String {
        switch draft.type {
        case "gmail_draft": return "Email Draft"
        case "slack_message": return "Slack Message"
        default: return "Draft"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(ghostTextTer)

                Text(typeLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ghostTextMut)
                    .tracking(0.5)

                Spacer()

                if let recipient = draft.recipient {
                    Text(recipient)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ghostTextMut)
                }
            }

            Text(draft.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ghostTextPri)

            Text(draft.preview)
                .font(.system(size: 11))
                .foregroundColor(ghostTextSec)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Spacer()

                Button(action: {}) {
                    Text("Reject")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ghostError.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Text("Approve")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ghostOnAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(ghostAccent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(ghostBgElev)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ghostBord, lineWidth: 0.5)
        )
    }
}
