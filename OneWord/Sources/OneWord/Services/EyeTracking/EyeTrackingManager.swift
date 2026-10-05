//
//  EyeTrackingManager.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(Vision)
import Vision
#endif

/// Gerenciador de rastreamento de atenção e orientação foveal via câmera frontal TrueDepth.
/// Pausa automaticamente a leitura RSVP ao detectar desvio de olhar ou ausência do usuário,
/// e monitora a fadiga óptica através da regra 20-20-20.
@Observable
@MainActor
public final class EyeTrackingManager: NSObject, Sendable {
    public static let shared = EyeTrackingManager()
    
    // MARK: - Estado Reativo
    public private(set) var isTracking: Bool = false
    public private(set) var isUserLookingAtScreen: Bool = true
    public internal(set) var isFatigueRestSuggested: Bool = false
    public private(set) var activeReadingDurationSeconds: TimeInterval = 0
    
    // Callbacks de evento
    public var onUserLookedAway: (() -> Void)?
    public var onUserLookedBack: (() -> Void)?
    
    #if os(iOS)
    private var cameraWorker: CameraCaptureWorker?
    private var lastFaceDetectedTime: Date = Date()
    private var consecutiveDistractedFrames: Int = 0
    #endif
    
    private var fatigueTimer: Timer?
    
    public override init() {
        super.init()
    }
    
    // MARK: - Ciclo de Vida do Rastreamento
    
    /// Inicia o monitoramento de atenção com a câmera frontal.
    public func startTracking() {
        guard !isTracking else { return }
        
        #if os(iOS)
        checkCameraPermission { [weak self] granted in
            guard let self, granted else { return }
            let worker = CameraCaptureWorker()
            self.cameraWorker = worker
            worker.start { [weak self] sampleBuffer in
                self?.processSampleBuffer(sampleBuffer)
            }
        }
        #endif
        
        startFatigueTimer()
        self.isTracking = true
    }
    
    /// Interrompe o monitoramento de câmera frontal e timers associados.
    public func stopTracking() {
        guard isTracking else { return }
        
        #if os(iOS)
        cameraWorker?.stop()
        cameraWorker = nil
        #endif
        
        fatigueTimer?.invalidate()
        fatigueTimer = nil
        self.isTracking = false
        self.isUserLookingAtScreen = true
    }
    
    // MARK: - Regra 20-20-20 (Descanso Ocular)
    
    private func startFatigueTimer() {
        fatigueTimer?.invalidate()
        activeReadingDurationSeconds = 0
        isFatigueRestSuggested = false
        
        fatigueTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.activeReadingDurationSeconds += 1.0
                // 20 minutos = 1200 segundos
                if self.activeReadingDurationSeconds >= 1200 && !self.isFatigueRestSuggested {
                    self.isFatigueRestSuggested = true
                }
            }
        }
    }
    
    /// Descarta o alerta de descanso óptico após o usuário relaxar a visão.
    public func dismissFatigueAlert() {
        isFatigueRestSuggested = false
        activeReadingDurationSeconds = 0
    }
    
    /// Descarta a sugestão de descanso 20-20-20.
    public func dismissFatigueSuggestion() {
        dismissFatigueAlert()
    }
    
    // MARK: - Configuração de Câmera iOS
    
    #if os(iOS)
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }
    
    private nonisolated func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self, error == nil else { return }
            let results = request.results as? [VNFaceObservation] ?? []
            
            Task { @MainActor in
                self.evaluateFaceObservations(results)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }
    #endif
}

// MARK: - Worker de Captura de Câmera (Isolado da MainActor)

#if os(iOS)
private final class CameraCaptureWorker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.oneword.eyetracking.queue", qos: .userInitiated)
    private var onSampleBuffer: ((CMSampleBuffer) -> Void)?
    
    func start(onSampleBuffer: @escaping (CMSampleBuffer) -> Void) {
        self.onSampleBuffer = onSampleBuffer
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.setupAndStart()
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let session = self.captureSession, session.isRunning {
                session.stopRunning()
            }
            self.captureSession = nil
            self.videoOutput = nil
            self.onSampleBuffer = nil
        }
    }
    
    private func setupAndStart() {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .low // Baixo consumo de bateria e processamento
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        session.startRunning()
        
        self.captureSession = session
        self.videoOutput = output
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onSampleBuffer?(sampleBuffer)
    }
}
#endif

// MARK: - Avaliação de Atenção Visual

#if os(iOS)
extension EyeTrackingManager {
    
    @MainActor
    private func evaluateFaceObservations(_ faces: [VNFaceObservation]) {
        guard let primaryFace = faces.first else {
            // Rosto não detectado no campo visual da câmera
            handleAttentionState(isAttentive: false)
            return
        }
        
        // Verifica se a rotação (yaw) do rosto está voltada para a tela
        var isFacingScreen = true
        if let yaw = primaryFace.yaw?.doubleValue {
            // Ângulo em radianos (> 0.40 rad ou ~23° indica olhar para longe)
            if abs(yaw) > 0.40 {
                isFacingScreen = false
            }
        }
        
        handleAttentionState(isAttentive: isFacingScreen)
    }
    
    @MainActor
    private func handleAttentionState(isAttentive: Bool) {
        if isAttentive {
            consecutiveDistractedFrames = 0
            if !isUserLookingAtScreen {
                isUserLookingAtScreen = true
                onUserLookedBack?()
            }
        } else {
            consecutiveDistractedFrames += 1
            // Dispara após ~3 frames consecutivos sem atenção (~0.4s) para evitar falsos positivos
            if consecutiveDistractedFrames >= 3 && isUserLookingAtScreen {
                isUserLookingAtScreen = false
                onUserLookedAway?()
            }
        }
    }
}
#endif
