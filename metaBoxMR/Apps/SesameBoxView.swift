//
//  SesameBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/25.
//

import SwiftUI
import Speech

class SesameBox: ObservableObject {
    @Published var recognizedText: String = ""
}

struct SesameBoxView: View {
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let passPhrase = "開閉"
    
    @StateObject private var sesameBox = SesameBox()
    @State private var isRecording: Bool = false
    @State private var isFinal: Bool = false
    
    // 音声認識へのアクセス認証
    func startRecognition() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                do {
                    try startRecording()
                } catch {
                    print("録音の開始に失敗しました: \(error)")
                }
            } else {
                print("音声認識の許可がありません")
            }
        }
    }
    
    // 音声認識を開始
    func startRecording() throws {
        // 動作中の場合、タスクを終了する
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        self.isRecording = true
        
        Task {
            sesameBox.recognizedText = ""
        }
        
        // オーディオセッションを開始
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // 既存のタップを削除（重複インストール防止）<- どういうこと？
        inputNode.removeTap(onBus: 0)
        
        // 音声認識リクエスト
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("SFSpeechAudioBufferRecognitionRequest オブジェクトを作成できません")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true
        
        guard let speechRecognizer = speechRecognizer else {
            fatalError("音声認識機能は使用できません")
        }
        
        // 音声認識タスクを開始
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { (result, error) in
            if let result = result {
                sesameBox.recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.isRecording = false
            }
        }
        
        // マイク入力を設定
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("オーディオエンジンの起動に失敗しました: \(error)")
            self.isRecording = false
            throw error
        }
    }
    
    // パスフレーズ認証
    func unlockMethod() {
        if sesameBox.recognizedText == passPhrase {
            isRecording = false
            unlock()
            print("unlock")
        }
    }
    
    // 合言葉をリセット
    func resetSesame() {
        
    }
    
    // メインビュー
    var body: some View {
        VStack {
            if !isRecording {
                VStack {
                    Text("合言葉Box")
                        .padding()
                        .font(.title)
                    
                    HStack{
                        Button("合言葉リセット") {
                        }
                        Button("解錠") {
                            startRecognition()
                        }
                    
                    }
                }
                .transition(.blurReplace)
            } else if isRecording {
                VStack {
                    Text("合言葉を話してください")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "microphone.fill")
                        .font(.system(size: 72, weight: .semibold))
                        .padding()
                    Text(sesameBox.recognizedText)
                        .padding()
                        .font(.title)
                }
                .transition(.blurReplace)
            }
        }
        .background(Color.clear)
        .animation(.default, value: isRecording)
        .onChange(of: sesameBox.recognizedText) {
            unlockMethod()
        }

    }
    
    struct SesameBoxView_Previews: PreviewProvider {
        static var previews: some View {
            SesameBoxView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    SesameBoxView()
}
