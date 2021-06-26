//
//  ViewController.swift
//  ARPhotoViewerDemo
//
//  Created by DAYE JACK on 10/1/20.
//  Copyright © 2020 DAYE JACK. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var injuryLabel: UILabel!
    var planeColor: UIColor?
    var planeColorOff: UIColor?
    var chosenImage: UIImage?
    var planes: [SCNNode] = []
    var e: EchoAR?
    
    let echoImgEntryId = "ef28bae9-5e6a-4174-9a64-c3773ff59e17" // ENTER YOUR ECHO AR ENTRY ID FOR A PICTURE FRAME
    
    var pictureFrameNode: SCNNode?
    
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
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(screenTapped(gesture:)))
        sceneView.addGestureRecognizer(gestureRecognizer)
        
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
                    self.injuryLabel.text = userText
                }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addPhotoTapped(_ sender: Any) {
        //when the user taps a photo

        let name = "Bandaid 2"
        let image = UIImage(named: name)

        if image == nil {
            print("missing image at: \(name)")
        }
        else {
            print("!!!IMAGE FOUND at: \(name)")
        }
        
        self.chosenImage = image;

        self.dismiss(animated: true) {
            //show a preview of the users selected image
            //and show text prompt to user
            self.previewImageView.image = image
            self.previewImageView.alpha = 1.0
        }
    }
    
    
    /*
     screenTapped(gesture:)
     takes a tap gesture recognizer as an argument
     calls addImage() -- to add an image on the tapped location
     */
    @objc func screenTapped(gesture: UITapGestureRecognizer){
        let gesturePos = gesture.location(in: self.sceneView)
        print("coordinates: " + gesturePos.debugDescription)
        //gesturePos = CGPoint(x: 200, y: 200)
        //get a 3D point from the tapped location
        //check if the user tapped an existing plane
        /*let hitTestResults = sceneView.hitTest(gesturePos, types: .existingPlaneUsingExtent)
        
        //check if there was a result to the hit test
        guard let hitTest = hitTestResults.first, let _ = hitTest.anchor else {
            return
        }
        
        //add image using hit test
         addImage(hitTest)*/
        doAdd(withGestureRecognizer: gesture)
    }
    
    func doAdd(withGestureRecognizer recognizer: UIGestureRecognizer){
            //get the location of the tap
            let tapLocation = recognizer.location(in: sceneView)


            //a hit test to see if the user has tapped on an existing plane
            let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

            //make sure a result of the hit test exists
            guard let hitTestResult = hitTestResults.first else { return }

            //get the translation, or where we will be adding our node
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
                let action = SCNAction.scale(by: 0.5, duration: 0.3)
                selectedNode.runAction(action)

                //set the name of the node (just in case we ever need it)
                //selectedNode.name = idArr![selectedInd]

                //add the node to our scene
                sceneView.scene.rootNode.addChildNode(selectedNode)
            }
        }
    
    func addImage(_ hitTest: ARHitTestResult){
        //create a plane
        let planeGeometry = SCNPlane(width: 0.1, height: 0.1)
        let material = SCNMaterial()
        planeGeometry.materials = [material]
        
        //check if the user has selected an image
        guard chosenImage != nil else{
            return
        }
        
        //attach the image to the plane
        material.diffuse.contents = chosenImage
        
        //create a node from our plane
        let imageNode = SCNNode(geometry: planeGeometry)
        
        //match the image transform to the hit test anchor transform
        imageNode.transform = SCNMatrix4(hitTest.anchor!.transform)
        
        //rotate the node so it stands up vertically, rather than lying flat
        imageNode.eulerAngles = SCNVector3(imageNode.eulerAngles.x + (-1 * .pi / 2), imageNode.eulerAngles.y /*+ (-1 * .pi / 2)*/, imageNode.eulerAngles.z + (1 * .pi / 2))
        
        //position node using the hit test
        imageNode.position = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z)
        
        //load picture frame from echoAR platform, using its entry id
        e!.loadSceneFromEntryID(entryID: echoImgEntryId, completion: { (scene) in
            //get the picture frame node
            guard let selectedNode = scene.rootNode.childNodes.first else {return}
            
            //position selected node (picture frame), slightly behind the image, and set the euler angles
            // of the selected node
            selectedNode.position = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z - 0.01)
            selectedNode.eulerAngles = imageNode.eulerAngles
            
            //scale down picture frame node
            //0.043 is a number arrived at through trial, that gives a good picture frame size for our image
            let action = SCNAction.scale(by: 0.043, duration: 0.3)
            selectedNode.runAction(action)
            
            //add picture frame to scene
            self.sceneView.scene.rootNode.addChildNode(selectedNode)
        })
        
        //add image to scene
        sceneView.scene.rootNode.addChildNode(imageNode)
        
    }
    
    //END image picker delegate
 
    
    //togglePlane(planeNode:): takes a SCNNode as an argument
    //depending on the state of the togglePlaneButton, changes the color
    //of planeNode. (either to fully transparent, or to a translucent green)

    
}

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

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        //add a plane node to the scene

        //get the width and height of the plane anchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)

        //create a new plane
        let plane = SCNPlane(width: w, height: h)

        //set the color of the plane
        plane.materials.first?.diffuse.contents = planeColor!

        //create a plane node from the scene plane
        let planeNode = SCNNode(geometry: plane)

        //get the x, y, and z locations of the plane anchor
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)

        //set the plane position to the x,y,z postion
        planeNode.position = SCNVector3(x,y,z)

        //turn the plane node to the correct orientation
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.eulerAngles.z = -.pi / 2

        //set the name of the plane
        planeNode.name = "plane"

        //add plane to scene
        node.addChildNode(planeNode)
        
        //save plane (so it can be edited later)
        planes.append(planeNode)
    }
}
