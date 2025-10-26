import SwiftUI

// Timer Settings Model
struct TimerSettings {
    var pomodoro: Int = 25        // minutes
    var shortBreak: Int = 5       // minutes
    var longBreak: Int = 15       // minutes
    var longBreakInterval: Int = 4 // number of pomodoros before long break
    var autoStartBreaks: Bool = false
    var autoStartPomodoros: Bool = false
}

// Timer Type Enum
enum TimerType {
    case pomodoro
    case shortBreak
    case longBreak
    
    var displayName: String {
        switch self {
        case .pomodoro:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
}

// Main Timer View
struct ZeroNoiseTimerView: View {
    @State private var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @State private var totalSetTime: Int = 25 * 60 // Total time set by user
    @State private var isActive: Bool = false
    @State private var timer: Timer?
    @State private var showSettings: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    // New states for Pomodoro functionality
    @State private var currentTimerType: TimerType = .pomodoro
    @State private var completedPomodoros: Int = 0
    @State private var settings = TimerSettings()
    
    // The angle of the drag handle in degrees.
    @State private var dragAngle: Double = 75.0
    
    var progress: Double {
        guard totalSetTime > 0 else { return 0 }
        return Double(timeRemaining) / Double(totalSetTime)
    }
    
    var minutesString: String {
        let minutes = timeRemaining / 60
        return String(format: "%02d", minutes)
    }
    
    var secondsString: String {
        let seconds = timeRemaining % 60
        return String(format: ":%02d", seconds)
    }
    
    // Calculate time from angle (clockwise from top)
    var timeFromAngle: Int {
        let minutes = Int(round(dragAngle / 3.0))
        return max(minutes, 0) * 60
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.95, green: 0.95, blue: 0.95)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Timer Type Label
                    Text(currentTimerType.displayName)
                        .font(.title2)
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    // Timer Display
                    ZStack {
                        // Thin outer circle (background)
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 300, height: 300)
                        
                        // Thick progress arc
                        Circle()
                            .trim(from: 0, to: isActive ? progress : (dragAngle / 360.0))
                            .stroke(timerColor(), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 300, height: 300)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: isActive ? 1 : 0), value: isActive ? progress : dragAngle)
                        
                        // Inner circle
                        Circle()
                            .stroke(timerColor(), lineWidth: 4)
                            .frame(width: 280, height: 280)
                        
                        // Clickable area (invisible circle that covers the entire inner area)
                        Circle()
                            .fill(Color.white.opacity(0.01)) // Nearly invisible but still interactive
                            .frame(width: 280, height: 280)
                            .onTapGesture(count: 2) {
                                // Double tap to restart
                                restartTimer()
                            }
                            .onTapGesture {
                                // Single tap to toggle
                                toggleTimer()
                            }
                        
                        // Time text
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text(minutesString)
                                .font(.system(size: 72, weight: .regular, design: .default))
                                .foregroundColor(.black)
                            
                            Text(secondsString)
                                .font(.system(size: 45, weight: .regular, design: .default))
                                .foregroundColor(.black)
                        }
                        .allowsHitTesting(false) // Make text non-interactive so taps pass through
                        
                        // Draggable indicator (only show when not active)
                        if !isActive {
                            Circle()
                                .fill(timerColor())
                                .frame(width: 24, height: 24)
                                .offset(y: -150)
                                .rotationEffect(.degrees(dragAngle))
                                .gesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .named("timerRing"))
                                        .onChanged { value in
                                            updateAngleFromDrag(
                                                location: value.location,
                                                geometry: geometry
                                            )
                                        }
                                )
                        }
                    }
                    .frame(width: 300, height: 300)
                    .coordinateSpace(name: "timerRing")
                    
                    Spacer()
                    
                    // Settings Button
                    Button(action: {
                        withAnimation(.spring()) {
                            showSettings = true
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(.black.opacity(0.6))
                            .frame(width: 44, height: 44)
                    }
                    .padding(.bottom, 30)
                }
                
                // Settings Sheet
                if showSettings {
                    SettingsView(
                        showSettings: $showSettings,
                        settings: $settings,
                        onSettingsChange: updateCurrentTimer
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height < -50 && !showSettings {
                            withAnimation(.spring()) {
                                showSettings = true
                            }
                        }
                    }
            )
        }
        .onAppear {
            setupInitialTimer()
        }
    }
    
    func timerColor() -> Color {
        switch currentTimerType {
        case .pomodoro:
            return Color.black
        case .shortBreak:
            return Color.blue
        case .longBreak:
            return Color.green
        }
    }
    
    func setupInitialTimer() {
        let minutes = settings.pomodoro
        timeRemaining = minutes * 60
        totalSetTime = minutes * 60
        dragAngle = Double(minutes) * 3.0
    }
    
    func updateCurrentTimer() {
        if !isActive {
            let minutes: Int
            switch currentTimerType {
            case .pomodoro:
                minutes = settings.pomodoro
            case .shortBreak:
                minutes = settings.shortBreak
            case .longBreak:
                minutes = settings.longBreak
            }
            timeRemaining = minutes * 60
            totalSetTime = minutes * 60
            dragAngle = Double(minutes) * 3.0
        }
    }
    
    func updateAngleFromDrag(location: CGPoint, geometry: GeometryProxy) {
        let center = CGPoint(x: 150, y: 150) // Center of 300x300 timer
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let angleRadians = atan2(vector.dy, vector.dx)
        var angleDegrees = angleRadians * 180 / .pi
        angleDegrees += 90
        if angleDegrees < 0 {
            angleDegrees += 360
        }
        
        dragAngle = angleDegrees
        let newTime = timeFromAngle
        timeRemaining = newTime
        totalSetTime = newTime
    }
    
    func toggleTimer() {
        if timeRemaining == 0 { return }
        
        if isActive {
            stopTimer()
        } else {
            startTimer()
        }
        isActive.toggle()
    }
    
    func startTimer() {
        totalSetTime = timeRemaining
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                isActive = false
                handleTimerComplete()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func handleTimerComplete() {
        // Play notification sound or haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        switch currentTimerType {
        case .pomodoro:
            completedPomodoros += 1
            if completedPomodoros % settings.longBreakInterval == 0 {
                currentTimerType = .longBreak
                let minutes = settings.longBreak
                timeRemaining = minutes * 60
                totalSetTime = minutes * 60
                dragAngle = Double(minutes) * 3.0
            } else {
                currentTimerType = .shortBreak
                let minutes = settings.shortBreak
                timeRemaining = minutes * 60
                totalSetTime = minutes * 60
                dragAngle = Double(minutes) * 3.0
            }
            
            // Auto-start breaks if enabled
            if settings.autoStartBreaks && timeRemaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startTimer()
                    isActive = true
                }
            }
            
        case .shortBreak, .longBreak:
            currentTimerType = .pomodoro
            let minutes = settings.pomodoro
            timeRemaining = minutes * 60
            totalSetTime = minutes * 60
            dragAngle = Double(minutes) * 3.0
            
            // Auto-start pomodoros if enabled
            if settings.autoStartPomodoros && timeRemaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startTimer()
                    isActive = true
                }
            }
        }
    }
    
    func restartTimer() {
        // Stop any active timer
        if isActive {
            stopTimer()
            isActive = false
        }
        
        // Reset to initial state
        currentTimerType = .pomodoro
        completedPomodoros = 0
        
        // Set timer to pomodoro duration
        let minutes = settings.pomodoro
        timeRemaining = minutes * 60
        totalSetTime = minutes * 60
        dragAngle = Double(minutes) * 3.0
        
        // Optional: Add haptic feedback for restart
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// Settings View
struct SettingsView: View {
    @Binding var showSettings: Bool
    @Binding var settings: TimerSettings
    let onSettingsChange: () -> Void
    
    @State private var tempSettings: TimerSettings
    
    init(showSettings: Binding<Bool>, settings: Binding<TimerSettings>, onSettingsChange: @escaping () -> Void) {
        self._showSettings = showSettings
        self._settings = settings
        self.onSettingsChange = onSettingsChange
        self._tempSettings = State(initialValue: settings.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            // Settings Header
            HStack {
                Button("Cancel") {
                    withAnimation(.spring()) {
                        showSettings = false
                    }
                }
                .foregroundColor(.black)
                
                Spacer()
                
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button("Done") {
                    settings = tempSettings
                    onSettingsChange()
                    withAnimation(.spring()) {
                        showSettings = false
                    }
                }
                .foregroundColor(.black)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            
            // Timer Duration Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                    Text("Timer Duration")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                
                VStack(spacing: 0) {
                    // Pomodoro
                    TimerSettingRow(
                        label: "Pomodoro",
                        value: $tempSettings.pomodoro,
                        minValue: 1,
                        maxValue: 60
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Short Break
                    TimerSettingRow(
                        label: "Short Break",
                        value: $tempSettings.shortBreak,
                        minValue: 1,
                        maxValue: 30
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Long Break
                    TimerSettingRow(
                        label: "Long Break",
                        value: $tempSettings.longBreak,
                        minValue: 1,
                        maxValue: 60
                    )
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Long Break Interval
                    TimerSettingRow(
                        label: "Long Break Interval",
                        value: $tempSettings.longBreakInterval,
                        minValue: 2,
                        maxValue: 10
                    )
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Auto-Start Section
            VStack(alignment: .leading, spacing: 20) {
                Text("Auto-Start")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                
                VStack(spacing: 0) {
                    // Auto Start Breaks
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto Start Breaks")
                                .foregroundColor(.black)
                            Text("Start breaks automatically")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $tempSettings.autoStartBreaks)
                            .tint(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Auto Start Pomodoros
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto Start Pomodoros")
                                .foregroundColor(.black)
                            Text("Start work time automatically")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $tempSettings.autoStartPomodoros)
                            .tint(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        withAnimation(.spring()) {
                            showSettings = false
                        }
                    }
                }
        )
    }
}

// Timer Setting Row Component
struct TimerSettingRow: View {
    let label: String
    @Binding var value: Int
    let minValue: Int
    let maxValue: Int
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.black)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    if value > minValue {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 20))
                        .foregroundColor(value > minValue ? .black : .gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                }
                .disabled(value <= minValue)
                
                Text("\(value)")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 40)
                
                Button(action: {
                    if value < maxValue {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(value < maxValue ? .black : .gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                }
                .disabled(value >= maxValue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }
}

// Preview
struct ZeroNoiseTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ZeroNoiseTimerView()
    }
}
