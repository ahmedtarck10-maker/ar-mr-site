import UIKit
import SceneKit
import ModelIO
import SceneKit.ModelIO
import CoreMotion
import UniformTypeIdentifiers
import simd

class ViewController: UIViewController, UIDocumentPickerDelegate {

    // Views & Scene
    var leftView: SCNView!
    var rightView: SCNView!
    var scene: SCNScene!
    var modelRoot = SCNNode()

    // Cameras
    var cameraParent = SCNNode()
    var leftCameraNode = SCNNode()
    var rightCameraNode = SCNNode()
    var ipd: Float = 0.064
    var cameraDistance: Float = 0.60

    // Motion
    let motion = CMMotionManager()
    var lastQuat = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    let smoothingFactor: Float = 0.12

    // UI
    var openButton: UIButton!
    var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupScene()
        setupCameras()
        setupUI()
        startMotion()
    }

    func setupViews() {
        view.backgroundColor = .black
        let halfW = view.bounds.width / 2.0
        leftView = SCNView(frame: CGRect(x: 0, y: 0, width: halfW, height: view.bounds.height))
        rightView = SCNView(frame: CGRect(x: halfW, y: 0, width: halfW, height: view.bounds.height))
        leftView.backgroundColor = .black
        rightView.backgroundColor = .black
        leftView.rendersContinuously = true
        rightView.rendersContinuously = true
        leftView.preferredFramesPerSecond = 60
        rightView.preferredFramesPerSecond = 60
        view.addSubview(leftView)
        view.addSubview(rightView)
    }

    func setupScene() {
        scene = SCNScene()
        let ambient = SCNLight(); ambient.type = .ambient; ambient.intensity = 700
        let ambientNode = SCNNode(); ambientNode.light = ambient; scene.rootNode.addChildNode(ambientNode)
        let directional = SCNLight(); directional.type = .directional; directional.intensity = 1500
        let dirNode = SCNNode(); dirNode.light = directional; dirNode.eulerAngles = SCNVector3(-.pi/3, 0, 0)
        scene.rootNode.addChildNode(dirNode)
        modelRoot = SCNNode(); scene.rootNode.addChildNode(modelRoot)
        cameraParent = SCNNode(); scene.rootNode.addChildNode(cameraParent)
        leftView.scene = scene; rightView.scene = scene
        leftView.antialiasingMode = .multisampling4X; rightView.antialiasingMode = .multisampling4X
    }

    func setupCameras() {
        let leftCam = SCNCamera(); leftCam.fieldOfView = 65; leftCam.zNear = 0.01; leftCam.zFar = 1000
        leftCameraNode.camera = leftCam; leftCameraNode.simdPosition = SIMD3<Float>(-ipd/2, 0, cameraDistance)
        cameraParent.addChildNode(leftCameraNode)
        let rightCam = SCNCamera(); rightCam.fieldOfView = 65; rightCam.zNear = 0.01; rightCam.zFar = 1000
        rightCameraNode.camera = rightCam; rightCameraNode.simdPosition = SIMD3<Float>(ipd/2, 0, cameraDistance)
        cameraParent.addChildNode(rightCameraNode)
        let toeInAngle: Float = 0.008
        leftCameraNode.eulerAngles.y = toeInAngle
        rightCameraNode.eulerAngles.y = -toeInAngle
        leftView.pointOfView = leftCameraNode
        rightView.pointOfView = rightCameraNode
    }

    func setupUI() {
        openButton = UIButton(type: .system)
        openButton.setTitle("Open Model", for: .normal)
        openButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        openButton.setTitleColor(.white, for: .normal)
        openButton.layer.cornerRadius = 8
        openButton.frame = CGRect(x: 16, y: view.safeAreaInsets.top + 12, width: 130, height: 42)
        openButton.addTarget(self, action: #selector(openTap), for: .touchUpInside)
        view.addSubview(openButton)
        statusLabel = UILabel(frame: CGRect(x: 16, y: openButton.frame.maxY + 8, width: 320, height: 24))
        statusLabel.textColor = .white; statusLabel.font = UIFont.systemFont(ofSize: 13); statusLabel.text = "Ready"
        view.addSubview(statusLabel)
    }

    @objc func openTap() {
        var types: [UTType] = []
        if let t = UTType(filenameExtension: "usdz") { types.append(t) }
        if let t = UTType(filenameExtension: "glb") { types.append(t) }
        if let t = UTType(filenameExtension: "gltf") { types.append(t) }
        if types.isEmpty { types = [UTType.data] }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        loadModel(from: url)
    }

    func loadModel(from url: URL) {
        statusLabel.text = "Loading \(url.lastPathComponent)..."
        modelRoot.childNodes.forEach { $0.removeFromParentNode() }
        let ext = url.pathExtension.lowercased()
        DispatchQueue.global(qos: .userInitiated).async {
            var loadedNode: SCNNode?
            if ext == "usdz" {
                if let scn = try? SCNScene(url: url, options: nil) {
                    let container = SCNNode()
                    for child in scn.rootNode.childNodes { container.addChildNode(child) }
                    loadedNode = container
                }
            } else if ext == "glb" || ext == "gltf" {
                let asset = MDLAsset(url: url)
                let sceneFromMDL = SCNScene(mdlAsset: asset)
                let container = SCNNode()
                for child in sceneFromMDL.rootNode.childNodes { container.addChildNode(child) }
                loadedNode = container
            }
            if let node = loadedNode { self.normalize(node: node) }
            DispatchQueue.main.async {
                if let node = loadedNode {
                    self.modelRoot.addChildNode(node)
                    self.statusLabel.text = "Loaded: \(url.lastPathComponent)"
                } else {
                    self.statusLabel.text = "Failed to load model"
                }
            }
        }
    }

    func normalize(node: SCNNode) {
        var min = SCNVector3Zero; var max = SCNVector3Zero
        node.__getBoundingBoxMin(&min, max: &max)
        let size = SCNVector3(max.x - min.x, max.y - min.y, max.z - min.z)
        let maxDim = max(size.x, max(size.y, size.z))
        let desired: Float = 0.28
        let scale = desired / max(0.0001, maxDim)
        node.scale = SCNVector3(scale, scale, scale)
        let center = SCNVector3(min.x + size.x/2, min.y + size.y/2, min.z + size.z/2)
        node.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        node.position = SCNVector3(0, -0.05, 0)
    }

    func startMotion() {
        guard motion.isDeviceMotionAvailable else {
            statusLabel.text = "Device motion not available"
            return
        }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: OperationQueue()) { [weak self] (motionData, error) in
            guard let s = self, let motion = motionData else { return }
            let q = motion.attitude.quaternion
            var current = simd_quatf(ix: Float(q.x), iy: Float(q.y), iz: Float(q.z), r: Float(q.w))
            current = simd_normalize(current)
            let blended = simd_slerp(s.lastQuat, current, s.smoothingFactor)
            s.lastQuat = blended
            DispatchQueue.main.async { s.cameraParent.simdOrientation = blended }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motion.stopDeviceMotionUpdates()
    }
}