//
//  SesameBoxView.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/25.
//

import SwiftUI
import Speech
import RealityKit

// 状態遷移
enum SesameBoxViewState {
    case top, speech, unlock
}

final class SesameBox: AppClass {
    static let shared = SesameBox()

    @Published var isRecording: Bool
    @Published var recognizedText: String
    @Published var passPhrase: String
    @Published var knockCount: Int
    @Published var currentState: SesameBoxViewState
    @Published var isLocked: Bool

    // 音声認識系
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private let mathClass = MathClass()
    
    // 初期化
    override init() {
        self.isRecording = false
        self.recognizedText = ""
        self.passPhrase = "開けて"
        self.knockCount = 0
        self.currentState = .top
        self.isLocked = false
    }

    // リセット
    override func reset() {
        self.isRecording = false
        self.recognizedText = ""
        self.knockCount = 0
        self.currentState = .top
        self.isLocked = false
    }

    // 衝突終了
    override func handleCollisionEnded(entityA: Entity, entityB: Entity) {
        // キーエンティティと手
        if entityA.name.contains("middleFingerIntermediateBase") && entityB.name.contains("metaBoxSkin") {

            knockCount += 1
            print("DEBUG!: Knock count: \(knockCount)")
        }
    }

    // ハンドトラッキング関係
    override func handTrackingInteraction(to scene: Entity) async {
        if knockCount >= 2 {
            await MainActor.run {
                self.currentState = .speech
                self.knockCount = 0
            }
        }
    }

    // ----- ローカル関数 ----- //

    // 音声認識へのアクセス認証
    func startRecognition() {
        // 現在の認証状態を確認
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
                    print("DEBUG!: Failed to start recording: \(error)")
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
                            print("DEBUG!: Failed to start recording: \(error)")
                        }
                    }
                } else {
                    print("DEBUG!: No permission for voice recognition")
                }
            }

        case .denied, .restricted:
            // 権限が拒否または制限されているので再度リクエストしない
            print("DEBUG!: Voice recognition permission is denied or restricted")

        @unknown default:
            // 将来のケースへのフォールバック
            print("DEBUG!: Unknown certification status")
        }
    }

    // 音声認識を開始
    func startRecording() throws {
        // 動作中の場合、タスクを終了する
        cleanupRecognition()

        // オーディオセッションを開始
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // 入力ノードを取得
        let inputNode = audioEngine.inputNode
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
            print("DEBUG!: Failed to start audio engine: \(error)")
            self.isRecording = false
            throw error
        }
    }

    // 音声認識を初期化
    func cleanupRecognition() {
        // オーディオエンジンの停止
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // 認識タスクの解放
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // オーディオセッションの非アクティブ化
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // 状態のリセット
        DispatchQueue.main.async {
            self.isRecording = false
            self.recognizedText = ""
        }
    }

    // パスフレーズ認証
    func unlockMethod() {
        if self.recognizedText == self.passPhrase {
            cleanupRecognition()
            unlock()
            self.currentState = .unlock
        }
    }

}

struct SesameBoxView: View {
    @StateObject private var appClass = SesameBox.shared

    // メインビュー
    var body: some View {
        VStack {
            switch appClass.currentState {
            case .speech:
                speechView
                    .transition(.blurReplace)
                    .onChange(of: appClass.recognizedText) {
                        appClass.unlockMethod()
                    }
            case .unlock:
                unlockView
                    .transition(.blurReplace)
            case .top:
                topView
                    .transition(.blurReplace)
            }
        }
        .background(Color.clear)
        .animation(.default, value: appClass.currentState)
    }

    // トップビュー
    var topView: some View {
        VStack {
            Text("Boxをノックして合言葉を入力してください")
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
                    appClass.cleanupRecognition()
                    appClass.currentState = .top
                }
            }
        }
        .onAppear() {
            appClass.startRecognition()
        }
        .transition(.blurReplace)
        .frame(width: 400, height: 400)
    }
    
    // 解除ビュー
    var unlockView: some View {
        VStack {
            Text("ロックが解除されました")
                .padding()
                .font(.title)
            
            Button("戻る") {
                appClass.currentState = .top
                
                // metaBoxを解錠
                unlock()
            }
            .padding()
        }
    }
}
