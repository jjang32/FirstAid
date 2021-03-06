//
//  ViewController.swift
//  ARPhotoViewerDemo
//
//  Created by DAYE JACK on 10/1/20.
//  Copyright © 2020 DAYE JACK. All rights reserved.
//

import UIKit
import Vision
import SceneKit
import ARKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var injuryLabel: UILabel!
    var planeColor: UIColor?
    var planeColorOff: UIColor?
    var chosenImage: UIImage?
    var planes: [SCNNode] = []
    var e: EchoAR?
    var makeMorePlanes: Bool = true
    var makeMoreBandages: Bool = true
    
    let echoImgEntryId = "ef28bae9-5e6a-4174-9a64-c3773ff59e17" // ENTER YOUR ECHO AR ENTRY ID FOR A PICTURE FRAME
    
    var pictureFrameNode: SCNNode?
    var imageSegmentationModel = DeepLabV3()
    var request :  VNCoreMLRequest?
    
    
    var segmentedImage: UIImage?
    var maskImage: UIImage?
    func predict(customRequest: VNCoreMLRequest?, customImage: UIImage?) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let request = customRequest else { fatalError() }
            let handler = VNImageRequestHandler(cgImage: (customImage?.cgImage)!, options: [:])
            do {
                print("Request Made")
                try handler.perform([request])
            }catch {
                print(error)
            }
        }
    }
    
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
            DispatchQueue.main.async {
                
                /*
                 Checks if the output is of type PixelBuffer or MultiArray:
                    - U2-Net return CVPixelBuffer
                    - Deep-Lab returns MLMultiArray
                */
                var top = Int.max, left = Int.max, right = Int.min, bottom = Int.min
                if let observations = request.results as? [VNPixelBufferObservation],
                   let segmentationmap = observations.first?.pixelBuffer {
                    self.maskImage = segmentationmap.createImage()
                }else if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                         let segmentationmap = observations.first?.featureValue.multiArrayValue {
                    if let (b, w, h) = segmentationmap.toRawBytes(min: 0, max: 255){
                        for i in 0...h - 1{
                            for j in 0...w - 1{
                                if(b[i * w  + j] == 255) {
                                    top = min(top, i)
                                    bottom = max(bottom, i)
                                    left = min(left, j)
                                    right = max(right, j)
                                }
                            }
                        }
        
                    }
                }
                print("all done")
            }
        }

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the color to use for the plane
        planeColor = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.6))
        
        //plane color off will be used as the color of our planes when they are toggled off
        planeColorOff = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.0))
        
        //initialize our echo ar object
        e = EchoAR()
        
        //set scene view to automatically add omni directional light when needed
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        setUpModel()
    }
    
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: imageSegmentationModel.model) {
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            
            request?.imageCropAndScaleOption = .scaleFill
            
        } else {
            fatalError()
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //set our session configuration, so we are tracking vertical planes
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)

        sceneView.delegate = self
        
        //show debug feature points
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        //add gesture recognizer, to perform some action whenever the user taps
        //the scene view
        
        //make the view and text that appear when a user adds an image invisible
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //when the view appears, present an alert to the user
        //letting them know to scan a horizontal surface
        let alert = UIAlertController(title: "Injury", message: "What type of injury do you need help with?", preferredStyle: .alert)
        alert.addTextField { (textField) in
            
        }
        
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
                    guard let textField = alert?.textFields?[0], let userText = textField.text else { return }
                    print("User text: \(userText)")
                if (userText.lowercased() == "broken arm" ||                        userText.lowercased() == "broken leg" ||
                        userText.lowercased() == "gunshot wound" ||
                        userText.lowercased() == "stab wound" ||
                        userText.lowercased() == "i'm dying") {
                            self.callNumber(phoneNumber: "2407071760")
                    }
                    self.injuryLabel.text = userText
                    self.injuryLabel.isHidden = false
                }))
        
        self.present(alert, animated: true, completion: nil)
    }
        
    private func callNumber(phoneNumber: String) {
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func addModel(_ sender: Any) {
        if (!makeMoreBandages) {
            return
        }

        let crapLocation = CGPoint(x: 500, y: 100)
        let temp = sceneView.snapshot()
        //let helper = segMeth()
        predict(customRequest: self.request, customImage: temp)

        let hitTestResults = sceneView.hitTest(crapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        
        let translation = SCNVector3Make(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        let x = translation.x
        let y = translation.y
        let z = translation.z

       //load scene (bandage 3d model) from echoAR using the entry id of the users selected button
        e!.loadSceneFromEntryID(entryID: "f31430d6-52a2-49b6-bc87-9bc4ca37e673") { (selectedScene) in
            //make sure the scene has a scene node
            guard let selectedNode = selectedScene.rootNode.childNodes.first else {return}

            //set the position of the node
            selectedNode.position = SCNVector3(x,y,z)

            //scale down the node using our scale constants
            let action = SCNAction.scale(by: 0.035, duration: 0)
            selectedNode.runAction(action)

            //set the name of the node (just in case we ever need it)
            //selectedNode.name = idArr![selectedInd]

            //add the node to our scene
            sceneView.scene.rootNode.addChildNode(selectedNode)
        }
        makeMoreBandages = false;
    }
}

// UPDATES CURRENT PLANE
//MARK: ARSCN View Delegate
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else {return}

        //update the plane node, as plane anchor information updates

        //get the width and the height of the planeAnchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)

        //set the plane to the new width and height
        plane.width = w
        plane.height = h

        //get the x y and z position of the plane anchor
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)

        //set the nodes position to the new x,y, z location
        planeNode.position = SCNVector3(x, y, z)
    }

    // MAKES A NEW PLANE
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        if (!makeMorePlanes) {
            return
        }
            
        //add a plane node to the scene

        //get the width and height of the plane anchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)

        //create a new plane
        let plane = SCNPlane(width: w, height: h)
        makeMorePlanes = false

        //set the color of the plane
        plane.materials.first?.diffuse.contents = planeColor!

        //create a plane node from the scene plane
        let planeNode = SCNNode(geometry: plane)

        //get the x, y, and z locations of the plane anchor
        var x = CGFloat(planeAnchor.center.x)
        var y = CGFloat(planeAnchor.center.y)
        var z = CGFloat(planeAnchor.center.z)
        
        x = 0
        y = 0
        z = 0

        //set the plane position to the x,y,z postion
        planeNode.position = SCNVector3(x,y,z)

        //turn the plane node to the correct orientation
        planeNode.eulerAngles.x = -.pi / 2

        //set the name of the plane
        planeNode.name = "plane"

        //add plane to scene
        node.addChildNode(planeNode)
        
        //save plane (so it can be edited later)
        planes.append(planeNode)
    }
}
