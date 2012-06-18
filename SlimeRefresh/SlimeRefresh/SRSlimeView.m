//
//  SRAnimationView.m
//  SlimeRefresh
//
//  Created by zrz on 12-6-15.
//  Copyright (c) 2012年 zrz. All rights reserved.
//

#import "SRSlimeView.h"
#import "SRDefine.h"
#import <QuartzCore/QuartzCore.h>

NS_INLINE CGFloat distansBetween(CGPoint p1 , CGPoint p2) {
    return sqrtf((p1.x - p2.x)*(p1.x - p2.x) + (p1.y - p2.y)*(p1.y - p2.y));
}

NS_INLINE CGPoint pointLineToArc(CGPoint center, CGPoint p2, float angle, CGFloat radius) {
    float angleS = atan2f(p2.y - center.y, p2.x - center.x);
    float angleT = angleS + angle;
    float x = radius * cosf(angleT);
    float y = radius * sinf(angleT);
    return CGPointMake(x + center.x, y + center.y);
}

@implementation SRSlimeView {
    __unsafe_unretained id  _target;
    SEL     _action;
    //CGPoint     _tempPoint;
}

@synthesize viscous = _viscous, toPoint = _toPoint;
@synthesize startPoint = _startPoint, skinColor = _skinColor;
@synthesize bodyColor = _bodyColor, radius = _radius;
@synthesize missWhenApart = _missWhenApart, type = _type;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor clearColor];
        
        _toPoint = _startPoint = CGPointMake(frame.size.width / 2,
                                             frame.size.height / 2);
        _viscous = 55.0f;
        _radius = 13.0f;
        _bodyColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
        _skinColor = [UIColor colorWithWhite:0.8f alpha:0.9f];
        
        _missWhenApart = YES;
    }
    return self;
}

//- (void)setFrame:(CGRect)frame
//{
//    [super setFrame:frame];
//    _toPoint = _startPoint = CGPointMake(frame.size.width / 2,
//                                         frame.size.height / 2);
//    [self setNeedsDisplay];
//}

- (void)setStartPoint:(CGPoint)startPoint
{
    if (CGPointEqualToPoint(_startPoint, startPoint))return;
    _startPoint = startPoint;
    self.layer.anchorPoint = _startPoint;
    [self setNeedsDisplay];
}

- (void)setToPoint:(CGPoint)toPoint
{
    if (CGPointEqualToPoint(_toPoint, toPoint))return;
    _toPoint = toPoint;
    [self setNeedsDisplay];
}

- (UIBezierPath*)bodyPath:(CGFloat)startRadius end:(CGFloat)endRadius percent:(float)percent
{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    float angle1 = M_PI/3 + (M_PI / 6 /*M_PI/2 - M_PI/3*/) * percent;
    
    CGPoint sp1 = pointLineToArc(_startPoint, _toPoint,
                                 angle1, startRadius),
            sp2 = pointLineToArc(_startPoint, _toPoint,
                                 -angle1, startRadius),
            ep1 = pointLineToArc(_toPoint, _startPoint,
                                 M_PI/2, endRadius),
            ep2 = pointLineToArc(_toPoint, _startPoint,
                                 -M_PI/2, endRadius);
    
    CGPoint mp1 = CGPointMake((sp2.x + ep1.x)/2, (sp2.y + ep1.y)/2),
            mp2 = CGPointMake((sp1.x + ep2.x)/2, (sp1.y + ep2.y)/2),
            mm = CGPointMake((mp1.x + mp2.x)/2, (mp1.y + mp2.y)/2);
    float p = distansBetween(mp1, mp2) / 2 / endRadius * (0.9 + percent/10);
    mp1 = CGPointMake((mp1.x - mm.x)/p + mm.x, (mp1.y - mm.y)/p + mm.y);
    mp2 = CGPointMake((mp2.x - mm.x)/p + mm.x, (mp2.y - mm.y)/p + mm.y);
    
    [path moveToPoint:sp1];
    float angleS = atan2f(_toPoint.y - _startPoint.y,
                          _toPoint.x - _startPoint.x);
    [path addArcWithCenter:_startPoint
                    radius:startRadius
                startAngle:angleS + angle1
                  endAngle:angleS + M_PI*2 - angle1
                 clockwise:YES];
    [path addQuadCurveToPoint:ep1
                 controlPoint:mp1];
    angleS = atan2f(_startPoint.y - _toPoint.y,
                    _startPoint.x - _toPoint.x);
    [path addArcWithCenter:_toPoint
                    radius:endRadius
                startAngle:angleS + M_PI/2
                  endAngle:angleS + M_PI*3/2 
                 clockwise:YES];
    [path addQuadCurveToPoint:sp1
                 controlPoint:mp2];
    
    return path;
}

- (void)drawRect:(CGRect)rect
{
    float percent = 1 - distansBetween(_startPoint , _toPoint) / _viscous;
    switch (_type) {
        case SRSlimeTypeNormal:
            if (percent == 1) {
                CGContextRef context = UIGraphicsGetCurrentContext();
                [_bodyColor setFill];
                [_skinColor setStroke];
                CGContextSetLineWidth(context, 2);
                CGContextAddArc(context, _startPoint.x,
                                _startPoint.y, _radius,
                                0, 2*M_PI, 1);
                CGContextDrawPath(context, kCGPathFillStroke);
            }else {
                CGFloat startRadius = _radius * (kStartTo + (1-kStartTo)*percent);
                [_bodyColor setFill];
                [_skinColor setStroke];
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                CGFloat endRadius = _radius * (kEndTo + (1-kEndTo)*percent);
                UIBezierPath *path = [self bodyPath:startRadius
                                                end:endRadius
                                            percent:percent];
                CGContextSetLineWidth(context, 2);
                CGContextAddPath(context, path.CGPath);
                CGContextDrawPath(context, kCGPathFillStroke);
                if (percent <= 0) {
                    _type = SRSlimeTypeShortening;
                    [_target performSelector:_action
                                  withObject:self];
                    [self performSelector:@selector(scaling)
                               withObject:nil
                               afterDelay:kAnimationInterval];
                }
            }
            break;
            
        default:
            break;
    }
}

- (void)scaling
{
    self.toPoint = CGPointMake((_toPoint.x + _startPoint.x)*0.9,
                               (_toPoint.y + _startPoint.y)*0.9);
    float p = distansBetween(_startPoint, _toPoint) / _viscous;
    self.layer.transform = CATransform3DMakeScale(p, p, 1);
    
    [self performSelector:@selector(scaling)
               withObject:nil
               afterDelay:kAnimationInterval];
}

- (void)setPullApartTarget:(id)target action:(SEL)action
{
    _target = target;
    _action = action;
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    if (!hidden) {
        self.layer.transform = CATransform3DMakeScale(1, 1, 1);
    }
}

@end
