/**************************************************************************
* Copyright (C) echoAR, Inc. 2018-2020.
* echoAR, Inc. proprietary and confidential.
* Use subject to the terms of the Terms of Service available at
* https://www.echoar.xyz/terms, or another agreement
* between echoAR, Inc. and you, your company or other organization.
**************************************************************************/

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var injuryLabel: UILabel!
    var e:EchoAR!;
    
    //variables to store data for horizontal planes
    var planeColor: UIColor?
    var planeColorOff: UIColor?
    var myPlaneNode: SCNNode?
    var myPlanes: [SCNNode] = []
    var makeMorePlanes: Bool = true
    var makeMoreBandages: Bool = true
    
    //echoAR entry id's for 3D models for app
    let treeId = "ef28bae9-5e6a-4174-9a64-c3773ff59e17" // insert your entry id here
    let picnicTableId = "ddb22b24-1acc-41a6-825d-fb2d78040f9c" // insert your entry id here
    let roadId = "32b22856-24af-43c4-bbbe-88ad98998a46" // insert your entry id here
    let poolId = "0916c8f6-5d31-4b66-9bf4-a5b1f4e6509f" // insert your entry id here
    let mailBoxId = "3952a84c-0b6a-4917-9e89-89bc7c318590" // insert your entry id here
    let houseId = "a294665c-7e9c-4d15-96de-fb750afded31" // insert your entry id here
    let deerId = "d356f8f6-1f60-4613-a108-80eb50ae3ded" // insert your entry id here
    let bikeId = "5c76694e-ec84-411e-b85c-670439717932" // insert your entry id here

    //buttons for selecting objects to add to sceneView
    
    @IBOutlet weak var treeButton: UIButton!
    
    
    //variables for keeping track of pan gesture state
    var panStartZ: CGFloat?
    var draggingNode: SCNNode?
    var lastPanLocation: SCNVector3?
    
    //selected index and id, for the object a user has selected
    //using choice buttons
    var selectedId: String?
    var selectedInd = 0
    
    //array of the echoAR entry id's of 3D models
    var idArr: [String]?
    
    //constants to scale down the nodes, when first added to sceneView
    var scaleConstants: [CGFloat]?


    override func viewDidLoad() {
        super.viewDidLoad()

        //set all model choice button alpha's to the deselect state

        selectedId = treeId
        treeButton.alpha = 1.0
        
        //array of all entry id's of models users can add
        idArr = [treeId, roadId, poolId, picnicTableId, mailBoxId, houseId, deerId, bikeId]
        
        //default scale constants for the objects (reducing their size to start)
        //(if you chose entries different from the suggested,
        //update these constants to match the size of the entries chosen)
        scaleConstants = [0.009, 0.0004, 0.002, 0.0001, 0.004, 0.003, 0.0004, 0.000013]

        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true

        e = EchoAR();
        
        //choose a color to use for the plane
        planeColor = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.6))
        planeColorOff = UIColor(red: CGFloat(102.0/255) , green: CGFloat(189.0/255), blue: CGFloat(60.0/255), alpha: CGFloat(0.0))



        //set scene view to automatically add omni directional light when needed
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //configure scene view session to detect horizontal planes
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
       
        sceneView.delegate = self
        
        //uncomment to see feature points
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
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
                        self.injuryLabel.isHidden = false
                    }))
            
            self.present(alert, animated: true, completion: nil)
        }
    

    //handlePinch(panGesture:) - takes a UIPinchGestureRecognizer as an argument
    //called whenever a user does a two finger pinch
    
    
    @IBAction func addModel(_ sender: Any) {
            /*if (!makeMoreBandages) {
                return
            }*/
            print("adding bandage")
            let crapLocation = CGPoint(x: 300, y: 300)
            
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
                
                //set orientation of the node
//                selectedNode.eulerAngles.x = -.pi / 2
//                selectedNode.eulerAngles.z = -.pi / 2

                //scale down the node using our scale constants
                let action = SCNAction.scale(by: 0.02, duration: 0)
                selectedNode.runAction(action)

                //set the name of the node (just in case we ever need it)
                //selectedNode.name = idArr![selectedInd]
                //add the node to our scene
                sceneView.scene.rootNode.addChildNode(selectedNode)
            }
            makeMoreBandages = false;
        }
    
   
    //isPlane(node:): takes an SCNNode as an argument
    //returns true if the node is named "plain" otherwise returns false
    func isPlane(node: SCNNode) -> Bool {
        guard  let name = node.name else {
            return false
        }
        if name == "plain"{
            return true
        }
        return false
    }
    
    // MARK: - ARSCNViewDelegate
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
        if (!makeMorePlanes) {
            return
        }
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
        
        //turn th plane node so it lies flat horizontally, rather than stands up vertically
        planeNode.eulerAngles.x = -.pi / 2
        
        //set the name of the plane
        planeNode.name = "plain"
        
        //save the plane (used to later toggle the transparency of th plane)
        myPlaneNode = planeNode
        myPlanes.append(planeNode)
        
        //add plane to scene
        node.addChildNode(planeNode)
        makeMorePlanes = false
    }
    
}

//Additional notes and credits:
//Apple Documentation, Tracking and Visual Planes - https://developer.apple.com/documentation/arkit/world_tracking/tracking_and_visualizing_planes
//Jayven Nhan, ArKit Horizontal Planes- https://www.appcoda.com/arkit-horizontal-plane/
//Sri Adatrao, ARkit detecting planes - https://machinethinks.com/arkit-detecting-planes-and-placing-objects/
//Benjamin Kindle, Dragging Objects in SceneKit and ARKit  - https://medium.com/@literalpie/dragging-objects-in-scenekit-and-arkit-3568212a90e5

