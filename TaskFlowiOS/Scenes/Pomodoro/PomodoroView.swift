//
//  PomodoroView.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI
import SwiftData
import AVFoundation

struct PomodoroView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appState: AppState
    @Query(sort: [SortDescriptor(\STTask.date)]) private var tasks: [STTask]

    @State private var currentPomodoro: STPomodoro?
    @State private var selectTask: STTask?
    @State private var isRunning = false
    @State private var elapsedSeconds: Double = 0
    @State private var showTaskPicker = false
    @State private var showEndConfirm = false
    @State private var showFinishAlert = false
    @State private var isRelaxing = false
    @State private var relaxElapsedSeconds: Double = 0
    
    @State private var audioPlayer: AVAudioPlayer?

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var estimatedSeconds: Int {
        (currentPomodoro?.estimatedMinutes ?? appState.setting?.pomodoroWorkMinutes ?? 25) * 60
    }
    private var relaxTotalSeconds: Int {
        (appState.setting?.pomodoroRelaxMinutes ?? 5) * 60
    }

    private enum Status {
        case idle, working, paused, relaxing
        var title: String {
            switch self {
            case .idle: return "Idle"
            case .working: return "Working"
            case .paused: return "Paused"
            case .relaxing: return "Relaxing"
            }
        }
        var actionTitle: String {
            switch self {
            case .idle: return "Start"
            case .working: return "Pause"
            case .paused: return "Continue"
            case .relaxing: return ""  // button disabled during relax
            }
        }
    }

    private var currentStatus: Status {
        if isRelaxing {
            return .relaxing
        } else if isRunning {
            return .working
        } else if elapsedSeconds > 0 {
            return .paused
        } else {
            return .idle
        }
    }

    private var remainingSeconds: Int {
        let rem = (currentStatus == .relaxing ? Double(relaxTotalSeconds) - relaxElapsedSeconds : Double(estimatedSeconds) - elapsedSeconds)
        return max(0, Int(ceil(rem)))
    }
    private var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Task selector
                HStack(spacing: 8) {
                    Text(currentPomodoro?.task?.name ?? selectTask?.name ?? "Select Task")
                        .font(.headline)
                    Button { showTaskPicker = true } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)

                // Progress circle with overlay
                CircleProgressView(
                    fraction: (currentStatus == .relaxing ? relaxElapsedSeconds : elapsedSeconds) / Double(currentStatus == .relaxing ? relaxTotalSeconds : estimatedSeconds)
                )
                .frame(width: 260, height: 260)
                .overlay(
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.largeTitle)
                            .monospacedDigit()
                        Text(currentStatus.title)
                            .font(.subheadline)
                    }
                )

                // Controls
                HStack(spacing: 40) {
                    if currentStatus != .relaxing {
                        Button(action: toggleStartPause) {
                            Text(currentStatus.actionTitle)
                                .frame(width: 80, height: 44)
                                .background(Color.accentColor.cornerRadius(8))
                                .foregroundColor(.white)
                        }
                    }
                    Button("End") {
                        showEndConfirm = true
                    }
                    .frame(width: 80, height: 44)
                    .background(Color.red.cornerRadius(8))
                    .foregroundColor(.white)
                    .disabled(currentPomodoro == nil)
                }
            }
            .navigationTitle("Pomodoro")
            .sheet(isPresented: $showTaskPicker) {
                TaskPickerView(
                    tasks: tasks.filter { !$0.isFinished },
                    onSelect: setTask
                )
            }
            .alert("Abandon Pomodoro?", isPresented: $showEndConfirm) {
                Button("Yes", role: .destructive, action: abandonPomodoro)
                Button("Cancel", role: .cancel) {}
            }
            .alert("Pomodoro finished!", isPresented: $showFinishAlert) {
                Button("Skip", role: .cancel) {}
                Button("Relax") {
                    isRelaxing = true
                    relaxElapsedSeconds = 0
                }
            }
            .onReceive(timer) { _ in
                switch currentStatus {
                case .working:
                    updateElapsed()
                case .relaxing:
                    relaxElapsedSeconds += 0.1
                    if relaxElapsedSeconds >= Double(relaxTotalSeconds) {
                        isRelaxing = false
                    }
                default:
                    break
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if currentStatus == .working { updateElapsed() }
            }
            .onAppear { restoreState() }
            .onDisappear { saveToAppState() }
        }
    }
    
    private func setTask(_ task: STTask) {
        selectTask = task
        currentPomodoro?.task = task
    }

    private func restoreState() {
        if let pom = appState.startingPomodoro {
            currentPomodoro = pom
            selectTask = pom.task
            elapsedSeconds = Date().timeIntervalSince(pom.startDate)
            isRunning = true
            clearAppStateData()
        } else if let pom = appState.currentPomodoro {
            currentPomodoro = pom
            selectTask = appState.selectTask
            elapsedSeconds = Date().timeIntervalSince(pom.startDate)
            isRunning = appState.isCurrentPomodoroRunning
            clearAppStateData()
        }
    }

    private func clearAppStateData() {
        appState.startingPomodoro = nil
        appState.currentPomodoro = nil
        appState.selectTask = nil
        appState.isCurrentPomodoroRunning = false
    }

    private func saveToAppState() {
        appState.currentPomodoro = currentPomodoro
        appState.isCurrentPomodoroRunning = isRunning
        appState.selectTask = selectTask
    }

private func updateElapsed() {
    // Increment by the timer interval
    elapsedSeconds += 0.1
    if elapsedSeconds >= Double(estimatedSeconds) {
        finishPomodoro()
    }
}

    private func finishPomodoro() {
        guard let pom = currentPomodoro else { return }
        isRunning = false
        pom.task = selectTask
        pom.status = .finished
        pom.endDate = Date()
        pom.finishedMinutes = pom.estimatedMinutes
        try? context.save()
        elapsedSeconds = 0

        if let url = Bundle.main.url(forResource: "alert", withExtension: "wav") {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        }
        
        showFinishAlert = true
        currentPomodoro = nil
    }

    private func toggleStartPause() {
        if currentPomodoro == nil {
            createPomodoro()
        }
        isRunning.toggle()
    }

    private func createPomodoro() {
        let pom = STPomodoro(
            task: selectTask,
            startDate: Date(),
            estimatedMinutes: appState.setting?.pomodoroWorkMinutes ?? 25
        )
        context.insert(pom)
        try? context.save()
        currentPomodoro = pom
        elapsedSeconds = 0
    }

    private func abandonPomodoro() {
        guard let pom = currentPomodoro else { return }
        isRunning = false
        pom.task = selectTask
        pom.status = .abandoned
        pom.endDate = Date()
        pom.finishedMinutes = Int(elapsedSeconds / 60)
        try? context.save()
        elapsedSeconds = 0
        relaxElapsedSeconds = 0
        currentPomodoro = nil
    }
}

struct TaskPickerView: View {
    let tasks: [STTask]
    let onSelect: (STTask) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(tasks) { task in
                Button(task.name) {
                    onSelect(task)
                    dismiss()
                }
            }
            .navigationTitle("Select Task")
        }
    }
}

struct CircleProgressView: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 14))
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: CGFloat(min(fraction, 1)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.5)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 260, height: 260)
                .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.1), value: fraction)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: STTask.self, STPomodoro.self, STAppSetting.self, configurations: config)

    // Mock task
    let today = Date()
    let task = STTask(name: "Preview Task", date: today)
    container.mainContext.insert(task)

    // Mock setting
    let setting = STAppSetting()
    setting.pomodoroWorkMinutes = 1
    setting.pomodoroRelaxMinutes = 1
    container.mainContext.insert(setting)

    // Mock AppState
    let appState = AppState()
    appState.setting = setting

    return NavigationStack {
        PomodoroView()
            .environmentObject(appState)
    }
    .modelContainer(container)
}
