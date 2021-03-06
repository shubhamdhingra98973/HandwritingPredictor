//
//  DrawingVC.swift
//  Handwriting-machine-takeover
//
//  Created by Shubham Dhingra on 02/07/20.
//  Copyright © 2020 Shubham Dhingra. All rights reserved.
//

import UIKit
import CoreML
import Vision

class DrawingVC : UIViewController {

    @IBOutlet weak var drawingImageView : UIImageView!
    @IBOutlet weak var predictionLabel : UILabel!
    
    var lastPoint = CGPoint.zero
    var swiped : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func predictBtnWasPressed(_ sender : Any){
        guard let predictionImage = drawingImageView.image else {return}
        makePrediction(image(with: predictionImage, scaledTo: CGSize(width: 28.0, height: 28.0)))
    }
}


extension DrawingVC {
    
    func makePrediction(_ image : UIImage){
       
        guard let model = try? VNCoreMLModel(for: handwriting().model) else {
            return
        }
        let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
        guard let ciImage = CIImage(image: image) else {return}
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        }
        catch {
            debugPrint(error)
        }
    }
    
    func resultsMethod(request : VNRequest , error : Error?){
        guard let results = request.results else {return}
        guard let resultsArray = results[0] as? VNCoreMLFeatureValueObservation else {return}
        guard let multiArrayValue = resultsArray.featureValue.multiArrayValue else {return}
        
        var prediction : NSNumber = 0
        var compare : NSNumber = 0
        var atIndex : Int = 0
        var i : Int = 0
        
        while i < multiArrayValue.count {
            compare = multiArrayValue[i]
            if compare.floatValue > prediction.floatValue {
                prediction = compare
                atIndex = i
            }
            i = i + 1
        }
        predictionLabel?.text = "Digit may be : \(atIndex)"
        debugPrint(results)
    }
    
    func image(with image : UIImage , scaledTo newSize : CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false , 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        drawingImageView.image = newImage
        return newImage ?? UIImage()
    }
}

extension DrawingVC {
   
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        drawingImageView.image = nil
        if let touch = touches.first {
            lastPoint = touch.location(in: drawingImageView)
            print(lastPoint)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: drawingImageView)
            drawLine(fromPoint: lastPoint, toPoint: currentPoint)
            
            lastPoint = currentPoint
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if swiped == false {
            drawLine(fromPoint: lastPoint, toPoint: lastPoint)
        }
    }
    
    
    func drawLine(fromPoint : CGPoint , toPoint : CGPoint){
      
        UIGraphicsBeginImageContext(drawingImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        drawingImageView?.image?.draw(in: CGRect(x: 0, y: 0, width: drawingImageView.frame.size.width, height: drawingImageView.frame.size.height))
        
        context?.move(to: CGPoint(x: fromPoint.x, y: fromPoint.y))
        context?.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))
        context?.setLineCap(.round)
        context?.setLineWidth(10.0)
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setBlendMode(.normal)
        context?.strokePath()
        
        drawingImageView?.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
    }
}
