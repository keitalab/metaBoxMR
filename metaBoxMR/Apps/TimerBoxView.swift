//
//  TimerBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/25.
//

import SwiftUI
import RealityKit

final class TimerBox: AppClass {
    static let shared = TimerBox()
}

struct TimerBoxView: View {
    @State private var timer: Timer? = nil
    @State private var remainingTime: TimeInterval = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    
    let minutesRange = Array(0...59)
    let secondsRange = Array(0...59)
    
    @State private var currentView: Int = 0
    
    // タイマーを開始
    @MainActor
    func startTimer() {
        remainingTime = TimeInterval(selectedMinutes * 60 + selectedSeconds)
        
        if remainingTime > 0 {
            currentView = 1
            Task {
                while remainingTime > 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    remainingTime -= 1
                    
                    if remainingTime <= 0 {
                        currentView = 2
                        stopTimer()
                        break
                    }
                }
            }
        }
    }
    
    // タイマーを停止
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // 残り時間のフォーマットを変更
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // メイン
    var body: some View {
        ZStack {
            switch currentView {
            case 1:
                lockView
                    .transition(.blurReplace)
            case 2:
                unlockView
                    .transition(.blurReplace)
            default:
                mainView
                    .transition(.blurReplace)
            }
        }
        .background(Color.clear)
        .animation(.default, value: currentView)
    }
    
    // タイマー設定
    var mainView: some View {
        VStack {
            Text("タイマーBox")
                .padding()
                .font(.title)
            
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
        }
    }
    
    // タイマー動作時
    var lockView: some View {
        VStack {
            Image(systemName: "lock")
                .font(.system(size: 72, weight: .semibold))
                .padding()
            Text(formatTime(remainingTime))
                .font(.system(size: 72, weight: .semibold))
                .padding(3)
                .contentTransition(.numericText())
            Text("時間までロックします")
                .font(.title3)
        }
    }
    
    // タイマー終了時
    var unlockView: some View {
        VStack {
            Text("ロックを解除できます")
                .padding()
                .font(.title)
            
            Button("解錠") {
                currentView = 0
                
                // metaBoxを解錠
                unlock()
            }
            .padding()
        }
    }
}
