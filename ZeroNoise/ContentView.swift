//
//  ContentView.swift
//  ZeroNoise
//
//  Created by Saw Thura Zaw on 10/11/25.
//

import SwiftUI

struct PomodoroTimerView: View {
    @State private var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @State private var isActive: Bool = false
    @State private var timer: Timer?
    
    let totalTime: Int = 25 * 60
    
    var progress: Double {
        Double(timeRemaining) / Double(totalTime)
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.95, green: 0.95, blue: 0.95)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Timer Display
                ZStack {
                    // Red progress circle (dashed)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.red,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round,
                                dash: [15, 10]
                            )
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    // Black inner circle
                    Circle()
                        .stroke(Color.black, lineWidth: 8)
                        .frame(width: 280, height: 280)
                    
                    // Time text
                    Text(timeString)
                        .font(.system(size: 72, weight: .regular, design: .default))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Start/Pause button
                Button(action: toggleTimer) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 4)
                        )
                }
                .padding(.bottom, 60)
            }
        }
    }
    
    func toggleTimer() {
        isActive.toggle()
        
        if isActive {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                isActive = false
                // Timer completed - you can add completion logic here
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// Preview
struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
    }
}
