//
//  SesameBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/25.
//

import SwiftUI
import Speech
import RealityKit

final class SesameBox: AppClass {
    static let shared = SesameBox()
    
    @Published var isRecording: Bool
    @Published var recognizedText: String
    @Published var passPhrase: String
    @Published var knockCount: Int
    @Published var currentView: Int
    @Published var isLocked: Bool
    
    // 音声認識系
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let mathClass = MathClass()
    
    // 初期化
    private override init() {
        self.isRecording = false
        self.recognizedText = ""
        self.passPhrase = "開けて"
        self.knockCount = 0
        self.currentView = 0
        self.isLocked = false
    }
    
    // 衝突終了
    override func handleCollisionEnded(entityA: Entity, entityB: Entity) {
        // キーエンティティと手
        if entityA.name.contains("middleFingerIntermediateBase") && entityB.name.contains("metaBoxSkin") {
            
            knockCount += 1
            print("Knock Count: \(knockCount)")
        }
    }
    
    // ハンドトラッキング関係
    override func handTrackingInteraction(to scene: Entity) async {
        if knockCount >= 2 {
            print("Unlock")
            
            await MainActor.run {
                self.currentView = 1
                self.knockCount = 0
            }
        }
    }
    
    // ----- ローカル関数 ----- //
    
    // 音声認識へのアクセス認証
    func startRecognition() {
        // 1. まず現在の認証状態を確認
        let status = SFSpeechRecognizer.authorizationStatus()
        
        switch status {
        case .authorized:
            // 既に認証済みなので、直接録音開始
            DispatchQueue.main.async {
                self.isRecording = true
            }
            Task {
                do {
                    try self.startRecording()
                } catch {
                    print("録音の開始に失敗しました: \(error)")
                }
            }
            
        case .notDetermined:
            // 初回（または未承認）なのでリクエスト実施
            SFSpeechRecognizer.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    // リクエストが許可されたら録音開始
                    DispatchQueue.main.async {
                        self.isRecording = true
                    }
                    Task {
                        do {
                            try self.startRecording()
                        } catch {
                            print("録音の開始に失敗しました: \(error)")
                        }
                    }
                } else {
                    print("音声認識の許可がありません")
                }
            }
            
        case .denied, .restricted:
            // 権限が拒否または制限されているので再度リクエストしない
            print("音声認識の許可が拒否または制限されています")
            
        @unknown default:
            // 将来のケースへのフォールバック
            print("未知の認証ステータスです")
        }
    }
    
    // 音声認識を開始
    func startRecording() throws {
        // 動作中の場合、タスクを終了する
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
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
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }

            // エラー・完了時の処理もメインスレッドで
            if error != nil {
                DispatchQueue.main.async {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    
                    self.isRecording = false
                }
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
    
    // 音声認識を停止
    func stopRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // AVAudioSessionの非アクティブ化
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.recognizedText = ""
        }
    }
    
    // パスフレーズ認証
    func unlockMethod() {
        if self.recognizedText == self.passPhrase {
            stopRecognition()
            unlock()
            print("unlock")
        }
    }
    
}

struct SesameBoxView: View {
    @StateObject private var appClass = SesameBox.shared
    
    // メインビュー
    var body: some View {
        VStack {
            switch appClass.currentView {
            case 1:
                speechView
                    .transition(.blurReplace)
                    .onChange(of: appClass.recognizedText) {
                        appClass.unlockMethod()
                    }
            case 2:
                settingView
                    .transition(.blurReplace)
            case 3:
                changePassPhraseView
                    .transition(.blurReplace)
            default:
                topView
                    .transition(.blurReplace)
            }
        }
        .background(Color.clear)
        .animation(.default, value: appClass.currentView)
    }
    
    // トップビュー
    var topView: some View {
        VStack {
        }
        .transition(.blurReplace)
        .frame(width: 400, height: 400)
    }
    
    // 合言葉認識ビュー
    var speechView: some View {
        VStack {
            Text("合言葉を話してください")
                .font(.system(size: 16, weight: .semibold))
            Image(systemName: "microphone.fill")
                .font(.system(size: 72, weight: .semibold))
                .padding()
            Text(appClass.recognizedText)
                .padding()
                .font(.title)
            HStack {
                Button("キャンセル") {
                    appClass.stopRecognition()
                    appClass.currentView = 0
                }
                Button("設定") {
                    appClass.stopRecognition()
                    appClass.currentView = 2
                }
            }
        }
        .onAppear() {
            appClass.startRecognition()
        }
        .transition(.blurReplace)
        .frame(width: 400, height: 400)
    }
    
    // 合言葉設定ビュー
    var settingView: some View {
        VStack(spacing: 20) {
            Text("合言葉を設定")
                .padding()
                .font(.title)
            
            VStack {
                Text("現在の合言葉")
                    .font(.title2)
                Text(appClass.passPhrase)
            }
            
            HStack {
                Button("合言葉を変更") {
                    appClass.currentView = 3
                }
                
                Button("戻る") {
                    appClass.currentView = 0
                }
            }
        }
        .transition(.blurReplace)
        .frame(width: 400, height: 400)
    }
    
    // 合言葉変更ビュー
    var changePassPhraseView: some View {
        VStack {
            Text("合言葉を話してください")
                .font(.system(size: 16, weight: .semibold))
            Image(systemName: "microphone.fill")
                .font(.system(size: 72, weight: .semibold))
                .padding()
            Text(appClass.recognizedText)
                .padding()
                .font(.title)
            HStack {
                Button("戻る") {
                    appClass.stopRecognition()
                    appClass.currentView = 0
                }
                Button("完了") {
                    appClass.passPhrase = appClass.recognizedText
                    appClass.stopRecognition()
                    appClass.currentView = 0
                }
            }
        }
        .onAppear() {
            appClass.startRecognition()
        }
        .transition(.blurReplace)
        .frame(width: 400, height: 400)
    }
}
