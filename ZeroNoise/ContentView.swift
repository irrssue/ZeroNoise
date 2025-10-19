import SwiftUI

// ZeroNoise - Focus Timer App

struct ZeroNoiseTimerView: View {
    @State private var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @State private var totalSetTime: Int = 25 * 60 // Total time set by user
    @State private var isActive: Bool = false
    @State private var timer: Timer?
    
    // The angle of the drag handle in degrees.
    // 0 is top, 90 is right, 180 is bottom, 270 is left.
    // Default: 25 minutes = (25/120) * 360 = 75 degrees.
    @State private var dragAngle: Double = 75.0
    
    var progress: Double {
        // Ensure we don't divide by zero if totalSetTime is 0
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
        // 360 degrees = 120 minutes (2 hours max)
        let minutes = Int(round(dragAngle / 3.0)) // 360 degrees / 120 minutes = 3 degrees per minute
        return max(minutes, 0) * 60 // Convert to seconds, allow 0 minutes
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(red: 0.95, green: 0.95, blue: 0.95)
                    .ignoresSafeArea()
                
                // Timer Display
                ZStack {
                    // Thin outer circle (background)
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 300, height: 300)
                    
                    // Thick progress arc (shows set time or countdown)
                    Circle()
                        .trim(from: 0, to: isActive ? progress : (dragAngle / 360.0))
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: isActive ? 1 : 0), value: isActive ? progress : dragAngle)
                    
                    // Inner circle
                    Circle()
                        .stroke(Color.black, lineWidth: 4)
                        .frame(width: 280, height: 280)
                    
                    // Time text with different sizes for minutes and seconds
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(minutesString)
                            .font(.system(size: 72, weight: .regular, design: .default))
                            .foregroundColor(.black)
                        
                        Text(secondsString)
                            .font(.system(size: 45, weight: .regular, design: .default))
                            .foregroundColor(.black)
                    }
                    .onTapGesture {
                        toggleTimer()
                    }
                    
                    // Draggable indicator (only show when not active)
                    if !isActive {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height: 24)
                            .offset(y: -150) // The radius of the timer ring
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
                .frame(width: geometry.size.width, height: geometry.size.height)
                .coordinateSpace(name: "timerRing")
            }
        }
    }
    
    /// Updates the timer's angle based on the drag gesture location.
    /// - Parameters:
    ///   - location: The location of the touch, provided in the "timerRing" coordinate space.
    ///   - geometry: The geometry proxy of the main view to find the center point.
    func updateAngleFromDrag(location: CGPoint, geometry: GeometryProxy) {
        // The center of the view, which is the center of our timer circle
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        // Calculate the vector from the center to the user's touch location
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        
        // Calculate the angle in radians from the positive X-axis (right)
        // atan2 provides a result between -pi and pi
        let angleRadians = atan2(vector.dy, vector.dx)
        
        // Convert to degrees (from -180 to 180)
        var angleDegrees = angleRadians * 180 / .pi
        
        // Shift so that 0 degrees is at the top (12 o'clock) instead of right (3 o'clock)
        angleDegrees += 90
        
        // Normalize to a 0-360 range
        if angleDegrees < 0 {
            angleDegrees += 360
        }
        
        // Update the state
        dragAngle = angleDegrees
        
        // Update the time based on the new angle
        let newTime = timeFromAngle
        timeRemaining = newTime
        totalSetTime = newTime
    }
    
    func toggleTimer() {
        if timeRemaining == 0 { return } // Don't start a 0-second timer
        
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
                // Reset to default 25 minutes after completion
                let defaultTime = 25 * 60
                timeRemaining = defaultTime
                totalSetTime = defaultTime
                dragAngle = 75.0 // (25 / 120) * 360
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// Preview
struct ZeroNoiseTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ZeroNoiseTimerView()
    }
}
