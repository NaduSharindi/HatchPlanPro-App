//
//  LiveScannerView.swift
//  HatchPlanPro
//
//  Created by GitHub Copilot on 2026-05-13.
//

import SwiftUI
import AVFoundation
import Vision
import Combine

struct LiveScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSessionViewModel
    @State private var showScanResult = false
    @State private var capturedScanResult: VisionScanResult?
    @StateObject private var cameraManager = CameraManager()
    @State private var detectedText: [String] = []
    @State private var confidence: Double = 0.0
    @State private var fieldsFound: Int = 0
    @State private var flashEnabled = false

    var body: some View {
        ZStack {
            // MARK: - Camera Preview
            if cameraManager.isSimulator {
                // Simulator placeholder
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.hatchGreen.opacity(0.6))
                        Text("SIMULATOR MODE")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("Camera preview requires a physical device")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            } else {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            }
            
            // MARK: - Dark overlay with transparent center
            VStack {
                // Top overlay
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                
                Spacer()
                
                // Bottom overlay
                Rectangle()
                    .fill(Color.black.opacity(0.5))
            }
            .ignoresSafeArea()
            
            // MARK: - Scan Guide Frame
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Crop frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hatchGreen, lineWidth: 2)
                        
                        // Corner markers
                        VStack {
                            HStack {
                                Image(systemName: "square")
                                    .font(.system(size: 16))
                                    .foregroundColor(.hatchGreen)
                                Spacer()
                                Image(systemName: "square")
                                    .font(.system(size: 16))
                                    .foregroundColor(.hatchGreen)
                            }
                            Spacer()
                            HStack {
                                Image(systemName: "square")
                                    .font(.system(size: 16))
                                    .foregroundColor(.hatchGreen)
                                Spacer()
                                Image(systemName: "square")
                                    .font(.system(size: 16))
                                    .foregroundColor(.hatchGreen)
                            }
                        }
                        .padding(12)
                    }
                    .frame(height: 250)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .ignoresSafeArea()
            
            // MARK: - Header with Vision Status Badge
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Vision System Active Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.hatchGreen)
                            .frame(width: 8, height: 8)
                        
                        Text("VISION SYSTEM ACTIVE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.hatchGreen.opacity(0.8)))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.3))
                
                Spacer()
            }
            
            // MARK: - Detected Data Overlays
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Flock ID
                        if !detectedText.isEmpty {
                            HStack(spacing: 8) {
                                Text("FLOCK ID:")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(detectedText.first ?? "---")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.hatchGreen)
                            }
                        }
                        
                        // Date
                        if detectedText.count > 1 {
                            HStack(spacing: 8) {
                                Text("DATE:")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(detectedText[1])
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.hatchGreen)
                            }
                        }
                        
                        // Confidence
                        HStack(spacing: 8) {
                            Text("CONFIDENCE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(String(format: "%.1f%%", confidence * 100))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.hatchGreen)
                        }
                        
                        // Fields Found
                        HStack(spacing: 8) {
                            Text("FIELDS FOUND")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(String(format: "%02d/05", fieldsFound))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.hatchGreen)
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // MARK: - Bottom Controls
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 0) {
                    // Flash Button
                    Button(action: {
                        flashEnabled.toggle()
                        cameraManager.toggleFlash(on: flashEnabled)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            
                            Text("FLASH")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Capture Button (Center)
                    Button {
                        performCapture()
                        showScanResult = capturedScanResult != nil
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)

                            Circle()
                                .stroke(Color.hatchGreen, lineWidth: 3)
                        }
                        .frame(width: 60, height: 60)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Manual Button
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            
                            Text("MANUAL")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.5))
                .ignoresSafeArea()
            }
            
            // Info text below scan frame
            VStack {
                HStack {
                    Spacer()
                    Text("Align verified attached certificate within the frame")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .padding(.bottom, 20)
                Spacer()
            }

            NavigationLink(destination: scanResultDestination, isActive: $showScanResult) {
                EmptyView()
            }
            .hidden()
        }
        .onAppear {
            cameraManager.requestCameraAccess()
            cameraManager.startSession()
            startVisionProcessing()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .navigationBarBackButtonHidden(true)
    }

    private var scanResultDestination: some View {
        Group {
            if let result = capturedScanResult {
                ScanResultView(scanResult: result)
            } else {
                EmptyView()
            }
        }
    }
    
    private func performCapture() {
        // Simulate capture - in production, extract from camera frame
        detectedText = ["298-AXB", "24/OCT/23"]
        confidence = 0.894
        fieldsFound = 3
        
        capturedScanResult = VisionScanResult(
            flockID: "298-AXB",
            scanDate: "24/OCT/23",
            confidence: confidence,
            fieldsFound: fieldsFound,
            rawText: "FLOCK ID: 298-AXB\nDATE: 24/OCT/23\nSTRAIN: COBB 500",
            timestamp: Date()
        )
    }
    
    private func startVisionProcessing() {
        // Vision processing would start here in production
        // Simulating detection for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            detectedText = ["298-AXB"]
            confidence = 0.75
            fieldsFound = 2
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var session = AVCaptureSession()
    @Published var isCameraAvailable = false
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    
    #if targetEnvironment(simulator)
    let isSimulator = true
    #else
    let isSimulator = false
    #endif
    
    func requestCameraAccess() {
        guard !isSimulator else {
            print("[CameraManager] Running on Simulator — camera not available")
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                self.setupCamera()
            }
        }
    }
    
    func setupCamera() {
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("[CameraManager] No back camera found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setSampleBufferDelegate(self, queue: queue)
            }
            
            DispatchQueue.main.async {
                self.isCameraAvailable = true
            }
        } catch {
            print("[CameraManager] Error setting up camera: \(error)")
        }
    }
    
    func startSession() {
        guard !isSimulator else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        guard !isSimulator else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func toggleFlash(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("[CameraManager] Error toggling flash: \(error)")
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Vision processing would happen here
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewControllerRepresentable {
    let cameraManager: CameraManager
    
    func makeUIViewController(context: Context) -> CameraPreviewViewController {
        let controller = CameraPreviewViewController()
        controller.session = cameraManager.session
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewViewController, context: Context) {}
}

class CameraPreviewViewController: UIViewController {
    var session: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let session = session else { return }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
}

#Preview {
    LiveScannerView()
        .environmentObject(AppSessionViewModel())
}
