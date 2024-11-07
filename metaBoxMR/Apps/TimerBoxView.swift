//
//  TimerBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/25.
//

import SwiftUI

struct TimerBoxView: View {
    @State private var timer: Timer? = nil
    @State private var remainingTime: TimeInterval = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    @State private var timerActive = false
    @State private var isLocked = false
    
    let minutesRange = Array(0...59)
    let secondsRange = Array(0...59)
    
    // タイマーを開始
    @MainActor
    func startTimer() {
        remainingTime = TimeInterval(selectedMinutes * 60 + selectedSeconds)
        isLocked = true
        
        if remainingTime > 0 {
            timerActive = true
            Task {
                while remainingTime > 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    remainingTime -= 1
                    
                    if remainingTime <= 0 {
                        timerActive = false
                        stopTimer()
                        break
                    }
                }
            }
        }
    }
    
    // タイマーを停止
    func stopTimer() {
        unlock()
        timer?.invalidate()
        timer = nil
    }
    
    func unlockBox() {
        isLocked = false
        unlock()
    }
    
    // 残り時間のフォーマットを変更
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // メインビュー
    var body: some View {
        VStack {
            Text("タイマーBox")
                .padding()
                .font(.title)
            VStack {
                if timerActive {
                    Image(systemName: "lock")
                        .font(.system(size: 72, weight: .semibold))
                        .padding()
                    Text(formatTime(remainingTime))
                        .font(.system(size: 72, weight: .semibold))
                        .padding(3)
                        .contentTransition(.numericText())
                    Text("時間までロックします")
                        .font(.system(size: 16, weight: .semibold))
                } else if !isLocked {
                    HStack {
                        Picker(selection: $selectedMinutes, label: Text("分")) {
                            ForEach(minutesRange, id: \.self) { minute in
                                Text("\(minute) 分").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        
                        Picker(selection: $selectedSeconds, label: Text("秒")) {
                            ForEach(secondsRange, id: \.self) { second in
                                Text("\(second) 秒").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                    }
                    .padding()
                    
                    Button("開始") {
                        startTimer()
                    }
                    .padding()
                } else {
                    Image(systemName: "lock.open")
                        .font(.system(size: 72, weight: .semibold))
                        .padding()
                    Button("解錠") {
                        unlockBox()
                    }
                    .padding()
                    Text("ロックが解除されました")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(width: 400, height: 300)
        }
        .frame(width: 400, height: 400)
        .background(Color.black.opacity(0))
    }
    
    struct TimerBoxView_Previews: PreviewProvider {
        static var previews: some View {
            TimerBoxView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    TimerBoxView()
}
