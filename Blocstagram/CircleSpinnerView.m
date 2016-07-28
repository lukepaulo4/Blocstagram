//
//  CircleSpinnerView.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/22/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "CircleSpinnerView.h"

@interface CircleSpinnerView ()

@property (nonatomic, strong) CAShapeLayer *circleLayer;

@end

@implementation CircleSpinnerView

//Create circleLayer by overriding the getter, and creating it the first time it's called. This is called Lazy Instantiation
- (CAShapeLayer*)circleLayer {
    if(!_circleLayer) {
        
        //Calcs a CGPoint representing the center of the arc (our arc is an entire circle). Then arcCenter is used to construct a CGRect. The spinning circle will fit inside this rect.
        CGPoint arcCenter = CGPointMake(self.radius+self.strokeThickness/2+5, self.radius+self.strokeThickness/2+5);
        CGRect rect = CGRectMake(0, 0, arcCenter.x*2, arcCenter.y*2);
        
        //Makes a UIBezierPath object. Bezier path is one that can have both straight and curved line segments. Below code makes a new bezier path in the shape of an arc, with the start and end angles in radians. smoothedPath reps a smooth circle
        UIBezierPath* smoothedPath = [UIBezierPath bezierPathWithArcCenter:arcCenter
                                                                     radius:self.radius
                                                                 startAngle:M_PI*3/2
                                                                   endAngle:M_PI/2+M_PI*5
                                                                  clockwise:YES];
        
        //Create CAShapeLayer, a core animation layer made form a bezier path. Other layers can be made from other things, such as images.
        _circleLayer = [CAShapeLayer layer];


        //Scale is 1.0 on regular screens, 2.0 on retina displays
        _circleLayer.contentsScale = [[UIScreen mainScreen] scale];
        _circleLayer.frame = rect;
        
        //Want clear center of circle so can see the heart.
        _circleLayer.fillColor = [UIColor clearColor].CGColor;
        
        //Core animation classes use CGColorRef instead of UIColor, so we convert them using CGColor
        _circleLayer.strokeColor = self.strokeColor.CGColor;
        _circleLayer.lineWidth = self.strokeThickness;
        
        //lineCap specifies the shape of the ends of the line. lineJoin specifies the shape of the joints between parts of the line.
        _circleLayer.lineCap = kCALineCapRound;
        _circleLayer.lineJoin = kCALineJoinBevel;
        
        //Assign circular path to the layer
        _circleLayer.path = smoothedPath.CGPath;
        
        //make a mask layer and set its size to be the same. Different parts of a layer can have different opacities, as indicated by its mask layer's alpha channel. Black pixels will render opaque and white pixels render transparent. This will allow the circle to have a gradient on it.
        CALayer *maskLayer = [CALayer layer];
        maskLayer.contents = (id)[[UIImage imageNamed:@"andle-mask"] CGImage];
        maskLayer.frame = _circleLayer.bounds;
        _circleLayer.mask = maskLayer;
        
        //specified in seconds
        CFTimeInterval animationDuration = 5;
        
        //Smooth, linear animation, as opposed to easing in or out. Speed of animation stays the same.
        CAMediaTimingFunction *linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        
        //Animates the layer's rotation from 0 to PI*2 (one full circle turn)
        animation.fromValue = @0;
        animation.toValue = @(M_PI*2);
        animation.duration = animationDuration;
        animation.timingFunction = linearCurve;
        animation.removedOnCompletion = NO;
        
        //Repeats forever
        animation.repeatCount = INFINITY;
        
        //fillMode specifies what happens when the animation is complete (you can opt to hide layers once an animation has ended.) In our case, we specifiy kCAFillModeForwards to leave the layer on screen after the animation.
        animation.fillMode = kCAFillModeForwards;
        animation.autoreverses = NO;
        
        //Add animation to the layer
        [_circleLayer.mask addAnimation:animation forKey:@"rotate"];
        
        
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = animationDuration;
        animationGroup.repeatCount = INFINITY;
        animationGroup.removedOnCompletion = NO;
        animationGroup.timingFunction = linearCurve;
        
        //Animates the start of the stroke
        CABasicAnimation *strokeStartAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
        strokeStartAnimation.fromValue = @0.015;
        strokeStartAnimation.toValue = @0.515;
        
        //Animates the end of the stroke
        CABasicAnimation *strokeEndAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeEndAnimation.fromValue = @0.485;
        strokeEndAnimation.toValue = @0.985;
        
        //Add animations to the circle layer and we're done building the animation
        animationGroup.animations = @[strokeStartAnimation, strokeEndAnimation];
        [_circleLayer addAnimation:animationGroup forKey:@"progress"];
        
    }
    
    return _circleLayer;
    
}

//Method to help ensure the circle animation is positioned properly. We'll call it from a few places. Just positions the circle layer in the center of the view.
- (void)layoutAnimatedLayer {
    [self.layer addSublayer:self.circleLayer];
    
    self.circleLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

//When we add a subview to another view using [UIView -addSubview:], the subview can react to this in [UIView -willMoveToSuperview:]. Let's implement this method to ensure our positioning is accurate.
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview != nil) {
        [self layoutAnimatedLayer];
    } else {
        [self.circleLayer removeFromSuperlayer];
        self.circleLayer = nil;
    }
}

//Update the position of the layer if the frame changes
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (self.superview != nil) {
        [self layoutAnimatedLayer];
    }
}

//If we change the radius of the circle, that will affect positioning as well. We can update this by overriding the setter (setRadius:) to recreate the circle layer
- (void)setRadius:(CGFloat)radius {
    _radius = radius;
    
    [_circleLayer removeFromSuperlayer];
     _circleLayer = nil;
     
     [self layoutAnimatedLayer];
}

//Inform self.circleLayer if the other two properties change (stroke width or color)
- (void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
    _circleLayer.strokeColor = strokeColor.CGColor;
}

- (void)setStrokeThickness:(CGFloat)strokeThickness {
    _strokeThickness = strokeThickness;
    _circleLayer.lineWidth = _strokeThickness;
}

//Finally, let's set some default values in the initializer and provide a hint about our size
- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.strokeThickness = 1;
        self.radius = 12;
        self.strokeColor = [UIColor redColor];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake((self.radius+self.strokeThickness/2+5)*2, (self.radius+self.strokeThickness/2+5)*2);
}

@end
