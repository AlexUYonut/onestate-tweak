#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ESP Overlay View
@interface ESPOverlayView : UIView {
    NSTimer *updateTimer;
}
@property (nonatomic, strong) NSMutableArray *entities;
@end

@implementation ESPOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.layer.zPosition = 999999;
        self.entities = [NSMutableArray array];
        
        // Update la fiecare 150ms (mai safe)
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 
                                                      repeats:YES 
                                                        block:^(NSTimer *timer) {
            @try {
                [self scanForEntities];
                [self setNeedsDisplay];
            } @catch (NSException *e) {
                // Previne crash-uri
            }
        }];
    }
    return self;
}

- (void)scanForEntities {
    @try {
        [self.entities removeAllObjects];
        
        UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
        if (!mainWindow) return;
        
        [self findPlayersInView:mainWindow];
    } @catch (NSException *e) {
        // Silent fail
    }
}

- (void)findPlayersInView:(UIView *)view {
    @try {
        for (UIView *subview in view.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            
            // Caută clase care ar putea fi playeri
            if ([className containsString:@"Player"] || 
                [className containsString:@"Character"] ||
                [className containsString:@"Entity"] ||
                [className containsString:@"Avatar"] ||
                [className containsString:@"Ped"] ||
                [className rangeOfString:@"3D" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                CGPoint screenPos = [subview convertPoint:subview.bounds.origin toView:self];
                
                if (CGRectContainsPoint(self.bounds, screenPos) && !subview.hidden && subview.alpha > 0.1) {
                    
                    NSString *displayName = @"Player";
                    CGFloat distance = 0;
                    
                    // Introspection safe
                    unsigned int propertyCount;
                    objc_property_t *properties = class_copyPropertyList([subview class], &propertyCount);
                    
                    for (unsigned int i = 0; i < propertyCount; i++) {
                        const char *propertyName = property_getName(properties[i]);
                        NSString *propName = [NSString stringWithUTF8String:propertyName];
                        
                        if ([propName containsString:@"name"] || [propName containsString:@"label"]) {
                            @try {
                                id value = [subview valueForKey:propName];
                                if ([value isKindOfClass:[NSString class]]) {
                                    displayName = value;
                                }
                            } @catch (NSException *e) {}
                        }
                        
                        if ([propName containsString:@"distance"] || [propName containsString:@"range"]) {
                            @try {
                                id value = [subview valueForKey:propName];
                                if ([value respondsToSelector:@selector(floatValue)]) {
                                    distance = [value floatValue];
                                }
                            } @catch (NSException *e) {}
                        }
                    }
                    free(properties);
                    
                    if (distance == 0) {
                        CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
                        distance = sqrtf(powf(screenPos.x - center.x, 2) + powf(screenPos.y - center.y, 2)) / 10.0;
                    }
                    
                    [self.entities addObject:@{
                        @"position": [NSValue valueWithCGPoint:screenPos],
                        @"name": displayName,
                        @"distance": @(distance),
                        @"view": subview,
                        @"className": className
                    }];
                }
            }
            
            [self findPlayersInView:subview];
        }
    } @catch (NSException *e) {
        // Silent fail
    }
}

- (void)drawRect:(CGRect)rect {
    @try {
        if (self.entities.count == 0) return;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        for (NSDictionary *entity in self.entities) {
            CGPoint pos = [entity[@"position"] CGPointValue];
            NSString *name = entity[@"name"];
            CGFloat distance = [entity[@"distance"] floatValue];
            UIView *view = entity[@"view"];
            
            UIColor *color;
            if (distance < 20) {
                color = [UIColor greenColor];
            } else if (distance < 50) {
                color = [UIColor yellowColor];
            } else {
                color = [UIColor redColor];
            }
            
            [color setStroke];
            [color setFill];
            
            CGRect viewBounds = [view convertRect:view.bounds toView:self];
            if (!CGRectIsEmpty(viewBounds) && CGRectGetWidth(viewBounds) > 0) {
                CGContextSetLineWidth(context, 2.0);
                CGContextStrokeRect(context, viewBounds);
                
                CGContextSetLineWidth(context, 1.0);
                CGContextMoveToPoint(context, rect.size.width/2, rect.size.height);
                CGContextAddLineToPoint(context, pos.x, pos.y);
                CGContextStrokePath(context);
                
                NSString *info = [NSString stringWithFormat:@"%@ [%.0fm]", name, distance];
                NSDictionary *attributes = @{
                    NSFontAttributeName: [UIFont boldSystemFontOfSize:11],
                    NSForegroundColorAttributeName: [UIColor whiteColor],
                    NSStrokeColorAttributeName: [UIColor blackColor],
                    NSStrokeWidthAttributeName: @(-3.0)
                };
                
                CGSize textSize = [info sizeWithAttributes:attributes];
                CGPoint textPos = CGPointMake(pos.x - textSize.width/2, CGRectGetMinY(viewBounds) - 20);
                [info drawAtPoint:textPos withAttributes:attributes];
                
                CGContextFillEllipseInRect(context, CGRectMake(pos.x - 3, pos.y - 3, 6, 6));
            }
        }
        
        // Status indicator
        NSString *statusInfo = [NSString stringWithFormat:@"ESP ON | Entities: %lu", (unsigned long)self.entities.count];
        NSDictionary *statusAttr = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
            NSForegroundColorAttributeName: [UIColor greenColor],
            NSStrokeColorAttributeName: [UIColor blackColor],
            NSStrokeWidthAttributeName: @(-2.0)
        };
        [statusInfo drawAtPoint:CGPointMake(10, 40) withAttributes:statusAttr];
        
    } @catch (NSException *e) {
        // Silent fail
    }
}

- (void)dealloc {
    [updateTimer invalidate];
}

@end

// Global
static ESPOverlayView *espOverlay = nil;
static BOOL espActivated = NO;

%hook UIApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    
    if (espActivated) return; // Previne activări multiple
    
    // DELAY DE 60 SECUNDE (1 minut)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            if (espOverlay) return;
            
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* scene in [[UIApplication sharedApplication] connectedScenes]) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        window = scene.windows.firstObject;
                        break;
                    }
                }
            } else {
                window = [[UIApplication sharedApplication] keyWindow];
            }
            
            if (window) {
                espOverlay = [[ESPOverlayView alloc] initWithFrame:window.bounds];
                [window addSubview:espOverlay];
                [window bringSubviewToFront:espOverlay];
                
                espActivated = YES;
                
                // Notificare vizuală subtilă
                UIView *notification = [[UIView alloc] initWithFrame:CGRectMake(20, 80, 200, 40)];
                notification.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                notification.layer.cornerRadius = 10;
                
                UILabel *label = [[UILabel alloc] initWithFrame:notification.bounds];
                label.text = @"✓ ESP Activat";
                label.textColor = [UIColor greenColor];
                label.font = [UIFont boldSystemFontOfSize:14];
                label.textAlignment = NSTextAlignmentCenter;
                [notification addSubview:label];
                
                [window addSubview:notification];
                
                // Dispare după 3 secunde
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.5 animations:^{
                        notification.alpha = 0;
                    } completion:^(BOOL finished) {
                        [notification removeFromSuperview];
                    }];
                });
            }
        } @catch (NSException *e) {
            // Previne crash
        }
    });
}

%end

%hook UIWindow

- (void)addSubview:(UIView *)view {
    %orig;
    
    @try {
        if (espOverlay && espOverlay.superview == self) {
            [self bringSubviewToFront:espOverlay];
        }
    } @catch (NSException *e) {}
}

%end
