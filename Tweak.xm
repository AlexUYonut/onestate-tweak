#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================
// ESP OVERLAY VIEW
// ============================================

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
        
        // Update ESP la fiecare 150ms
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 
                                                      repeats:YES 
                                                        block:^(NSTimer *timer) {
            @try {
                [self scanForEntities];
                [self setNeedsDisplay];
            } @catch (NSException *e) {
                NSLog(@"[ESP] Error in timer: %@", e);
            }
        }];
        
        NSLog(@"[ESP] Overlay initialized");
    }
    return self;
}

- (void)scanForEntities {
    @try {
        [self.entities removeAllObjects];
        
        UIWindow *mainWindow = nil;
        
        // iOS 13+
        if (@available(iOS 13.0, *)) {
            NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
            for (UIScene *scene in scenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                        mainWindow = windowScene.windows.firstObject;
                        break;
                    }
                }
            }
        }
        
        // Fallback pentru iOS mai vechi
        if (!mainWindow) {
            mainWindow = [UIApplication sharedApplication].keyWindow;
        }
        if (!mainWindow) {
            mainWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (mainWindow) {
            [self findPlayersInView:mainWindow];
        }
    } @catch (NSException *e) {
        NSLog(@"[ESP] Error scanning: %@", e);
    }
}

- (void)findPlayersInView:(UIView *)view {
    @try {
        // Evită să scanăm propriul overlay
        if ([view isKindOfClass:[ESPOverlayView class]]) {
            return;
        }
        
        for (UIView *subview in view.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            
            // Caută clase care ar putea fi entități din joc
            BOOL isPotentialEntity = (
                [className containsString:@"Player"] || 
                [className containsString:@"Character"] ||
                [className containsString:@"Entity"] ||
                [className containsString:@"Avatar"] ||
                [className containsString:@"Ped"] ||
                [className containsString:@"NPC"] ||
                [className containsString:@"Vehicle"] ||
                [className rangeOfString:@"3D" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [className rangeOfString:@"Game" options:NSCaseInsensitiveSearch].location != NSNotFound
            );
            
            if (isPotentialEntity && !subview.hidden && subview.alpha > 0.1) {
                CGRect viewFrame = [subview convertRect:subview.bounds toView:self];
                CGPoint screenPos = CGPointMake(CGRectGetMidX(viewFrame), CGRectGetMidY(viewFrame));
                
                // Verifică dacă e vizibil pe ecran
                if (CGRectContainsPoint(self.bounds, screenPos)) {
                    
                    NSString *displayName = @"Entity";
                    CGFloat distance = 0;
                    
                    // Încearcă să extragi info prin runtime inspection
                    unsigned int propertyCount;
                    objc_property_t *properties = class_copyPropertyList([subview class], &propertyCount);
                    
                    for (unsigned int i = 0; i < propertyCount && i < 50; i++) {
                        const char *propertyName = property_getName(properties[i]);
                        NSString *propName = [NSString stringWithUTF8String:propertyName];
                        
                        if ([propName rangeOfString:@"name" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                            @try {
                                id value = [subview valueForKey:propName];
                                if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                                    displayName = value;
                                }
                            } @catch (NSException *e) {}
                        }
                        
                        if ([propName rangeOfString:@"distance" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                            [propName rangeOfString:@"range" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                            @try {
                                id value = [subview valueForKey:propName];
                                if ([value respondsToSelector:@selector(floatValue)]) {
                                    distance = [value floatValue];
                                }
                            } @catch (NSException *e) {}
                        }
                    }
                    free(properties);
                    
                    // Calculează distanță aproximativă dacă nu am găsit-o
                    if (distance == 0) {
                        CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
                        CGFloat dx = screenPos.x - center.x;
                        CGFloat dy = screenPos.y - center.y;
                        distance = sqrtf(dx*dx + dy*dy) / 10.0;
                    }
                    
                    [self.entities addObject:@{
                        @"position": [NSValue valueWithCGPoint:screenPos],
                        @"name": displayName,
                        @"distance": @(distance),
                        @"view": subview,
                        @"className": className,
                        @"bounds": [NSValue valueWithCGRect:viewFrame]
                    }];
                }
            }
            
            // Recursiv prin toate subview-urile
            [self findPlayersInView:subview];
        }
    } @catch (NSException *e) {
        NSLog(@"[ESP] Error finding players: %@", e);
    }
}

- (void)drawRect:(CGRect)rect {
    @try {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) return;
        
        // Desenează entitățile
        for (NSDictionary *entity in self.entities) {
            CGPoint pos = [entity[@"position"] CGPointValue];
            NSString *name = entity[@"name"];
            CGFloat distance = [entity[@"distance"] floatValue];
            CGRect bounds = [entity[@"bounds"] CGRectValue];
            
            // Culoare bazată pe distanță
            UIColor *color;
            if (distance < 20) {
                color = [UIColor greenColor];
            } else if (distance < 50) {
                color = [UIColor yellowColor];
            } else {
                color = [UIColor redColor];
            }
            
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetFillColorWithColor(context, color.CGColor);
            
            // Desenează box
            if (!CGRectIsEmpty(bounds) && CGRectGetWidth(bounds) > 10 && CGRectGetHeight(bounds) > 10) {
                CGContextSetLineWidth(context, 2.0);
                CGContextStrokeRect(context, bounds);
                
                // Linie de la centru la entitate
                CGContextSetLineWidth(context, 1.0);
                CGContextMoveToPoint(context, rect.size.width/2, rect.size.height);
                CGContextAddLineToPoint(context, pos.x, pos.y);
                CGContextStrokePath(context);
                
                // Text cu info
                NSString *info = [NSString stringWithFormat:@"%@ [%.0fm]", name, distance];
                NSDictionary *attributes = @{
                    NSFontAttributeName: [UIFont boldSystemFontOfSize:11],
                    NSForegroundColorAttributeName: [UIColor whiteColor],
                    NSStrokeColorAttributeName: [UIColor blackColor],
                    NSStrokeWidthAttributeName: @(-3.0)
                };
                
                CGSize textSize = [info sizeWithAttributes:attributes];
                CGPoint textPos = CGPointMake(pos.x - textSize.width/2, CGRectGetMinY(bounds) - 20);
                
                // Asigură-te că textul e în bounds
                if (textPos.y < 0) textPos.y = CGRectGetMaxY(bounds) + 5;
                
                [info drawAtPoint:textPos withAttributes:attributes];
                
                // Dot în centru
                CGContextFillEllipseInRect(context, CGRectMake(pos.x - 3, pos.y - 3, 6, 6));
            }
        }
        
        // Status indicator
        NSString *statusInfo = [NSString stringWithFormat:@"ESP ACTIVE | Entities: %lu", (unsigned long)self.entities.count];
        NSDictionary *statusAttr = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
            NSForegroundColorAttributeName: [UIColor greenColor],
            NSStrokeColorAttributeName: [UIColor blackColor],
            NSStrokeWidthAttributeName: @(-2.0)
        };
        [statusInfo drawAtPoint:CGPointMake(10, 40) withAttributes:statusAttr];
        
        // Crosshair central
        CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
        CGContextSetLineWidth(context, 2.0);
        CGFloat centerX = rect.size.width / 2;
        CGFloat centerY = rect.size.height / 2;
        CGFloat crossSize = 10;
        
        // Linie orizontală
        CGContextMoveToPoint(context, centerX - crossSize, centerY);
        CGContextAddLineToPoint(context, centerX + crossSize, centerY);
        // Linie verticală
        CGContextMoveToPoint(context, centerX, centerY - crossSize);
        CGContextAddLineToPoint(context, centerX, centerY + crossSize);
        CGContextStrokePath(context);
        
    } @catch (NSException *e) {
        NSLog(@"[ESP] Error drawing: %@", e);
    }
}

- (void)dealloc {
    [updateTimer invalidate];
    NSLog(@"[ESP] Overlay deallocated");
}

@end

// ============================================
// GLOBAL VARIABLES
// ============================================

static ESPOverlayView *g_espOverlay = nil;
static BOOL g_espActivated = NO;

// ============================================
// INITIALIZATION FUNCTION
// ============================================

static void ActivateESP() {
    @try {
        NSLog(@"[ESP] Attempting to activate ESP...");
        
        if (g_espActivated) {
            NSLog(@"[ESP] Already activated, skipping");
            return;
        }
        
        UIWindow *window = nil;
        
        // iOS 13+
        if (@available(iOS 13.0, *)) {
            NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
            for (UIScene *scene in scenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                        window = windowScene.windows.firstObject;
                        NSLog(@"[ESP] Found window from scene");
                        break;
                    }
                }
            }
        }
        
        // Fallback
        if (!window) {
            window = [UIApplication sharedApplication].keyWindow;
            NSLog(@"[ESP] Using keyWindow");
        }
        if (!window) {
            window = [UIApplication sharedApplication].windows.firstObject;
            NSLog(@"[ESP] Using first window");
        }
        
        if (window) {
            NSLog(@"[ESP] Window found: %@", window);
            
            // Creează overlay-ul
            g_espOverlay = [[ESPOverlayView alloc] initWithFrame:window.bounds];
            [window addSubview:g_espOverlay];
            [window bringSubviewToFront:g_espOverlay];
            
            g_espActivated = YES;
            
            NSLog(@"[ESP] Overlay added to window");
            
            // Notificare vizuală
            UIView *notification = [[UIView alloc] initWithFrame:CGRectMake(
                (window.bounds.size.width - 220) / 2,
                100,
                220,
                50
            )];
            notification.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
            notification.layer.cornerRadius = 12;
            notification.layer.borderWidth = 2;
            notification.layer.borderColor = [UIColor greenColor].CGColor;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(notification.bounds, 10, 10)];
            label.text = @"✓ ESP ACTIVATED";
            label.textColor = [UIColor greenColor];
            label.font = [UIFont boldSystemFontOfSize:16];
            label.textAlignment = NSTextAlignmentCenter;
            [notification addSubview:label];
            
            [window addSubview:notification];
            [window bringSubviewToFront:notification];
            
            NSLog(@"[ESP] Notification shown");
            
            // Dispare după 3 secunde
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.5 animations:^{
                    notification.alpha = 0;
                } completion:^(BOOL finished) {
                    [notification removeFromSuperview];
                }];
            });
        } else {
            NSLog(@"[ESP] ERROR: No window found!");
        }
    } @catch (NSException *e) {
        NSLog(@"[ESP] EXCEPTION: %@", e);
    }
}

// ============================================
// CONSTRUCTOR - SE EXECUTĂ AUTOMAT LA LOAD
// ============================================

__attribute__((constructor))
static void InitializeESP() {
    NSLog(@"[ESP] Dylib loaded - constructor called");
    
    // Așteaptă ca app-ul să fie gata
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[ESP] Initial 2 second delay passed");
        
        // Observă când app-ul devine activ
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            NSLog(@"[ESP] App became active notification received");
            
            // Delay de 60 secunde după ce devine activ
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"[ESP] 60 second delay passed, activating ESP");
                ActivateESP();
            });
        }];
        
        // Dacă app-ul e deja activ, activează direct
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            NSLog(@"[ESP] App already active, starting 60s countdown");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"[ESP] 60 second delay passed, activating ESP");
                ActivateESP();
            });
        }
    });
}
