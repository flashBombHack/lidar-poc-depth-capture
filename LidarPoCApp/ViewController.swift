import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var depthImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        print("[INFO] viewDidLoad called")

        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showFeaturePoints]

        print("[INFO] ARSceneView configured with lighting and feature points")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("[INFO] viewWillAppear: Starting AR/LiDAR session")

        let config = ARWorldTrackingConfiguration()

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            print("[INFO] Scene reconstruction (mesh) supported and enabled")
        } else {
            print("[WARN] Scene reconstruction NOT supported on this device")
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
            print("[INFO] Scene depth supported and enabled")
        } else {
            print("[WARN] Scene depth NOT supported on this device")
        }

        sceneView.session.run(config)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        print("[INFO] AR session paused")
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depthMap = frame.sceneDepth?.depthMap else {
            print("[DEBUG] No depthMap in current frame")
            return
        }

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        print("[DATA] Frame with depth map size: \(width)x\(height)")

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)

        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)
        let floatArray = UnsafeBufferPointer(start: floatBuffer, count: width * height)
        let depthValues = Array(floatArray)

        if let min = depthValues.min(), let max = depthValues.max() {
            print("[DATA] Depth range in meters: min = \(String(format: "%.3f", min)), max = \(String(format: "%.3f", max))")
        }

        // Export a subset to JSON
        exportDepthData(depthValues: depthValues, width: width, height: height)

        // Convert to grayscale image
        let minDepth = depthValues.min() ?? 0
        let maxDepth = depthValues.max() ?? 1
        let pixels = depthValues.map { UInt8((($0 - minDepth) / (maxDepth - minDepth)) * 255) }

        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let providerRef = CGDataProvider(data: Data(pixels) as CFData)!

        if let cgImage = CGImage(width: width,
                                 height: height,
                                 bitsPerComponent: 8,
                                 bitsPerPixel: 8,
                                 bytesPerRow: width,
                                 space: grayColorSpace,
                                 bitmapInfo: bitmapInfo,
                                 provider: providerRef,
                                 decode: nil,
                                 shouldInterpolate: false,
                                 intent: .defaultIntent) {
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.depthImageView.image = image
            }
        }

        CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
    }

    func exportDepthData(depthValues: [Float32], width: Int, height: Int) {
        let downSampleRate = 20 // Only take 1 in every 20 values to limit file size
        let sampledData = stride(from: 0, to: depthValues.count, by: downSampleRate).map {
            round(depthValues[$0] * 1000) / 1000  // round to mm precision
        }

        let dataDict: [String: Any] = [
            "width": width,
            "height": height,
            "sampledDepthValues": sampledData
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted)
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("depth_data.json")
            try jsonData.write(to: fileURL)

            print("[EXPORT] Depth data exported to \(fileURL.path)")
        } catch {
            print("[ERROR] Failed to export depth data: \(error)")
        }
    }
}
