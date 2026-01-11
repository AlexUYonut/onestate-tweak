#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <substrate.h>

// ============================================
// UNITY IL2CPP DEFINITIONS
// ============================================

typedef struct Vector3 {
    float x;
    float y;
    float z;
} Vector3;

typedef struct Transform {
    void *object;
} Transform;

// Function pointers pentru Unity IL2CPP
void* (*il2cpp_domain_get_assemblies)(void* domain, size_t* size);
void* (*il2cpp_assembly_get_image)(void* assembly);
void* (*il2cpp_class_from_name)(void* image, const char* namespaze, const char* name);
void* (*il2cpp_class_get_method_from_name)(void* klass, const char* name, int argsCount);
void* (*il2cpp_class_get_methods)(void* klass, void** iter);
void* (*il2cpp_class_get_fields)(void* klass, void** iter);
void* (*il2cpp_domain_get)();
void* (*il2cpp_thread_attach)(void* domain);
void* (*il2cpp_object_new)(void* klass);
void* (*il2cpp_resolve_icall)(const char* name);
void* (*il2cpp_array_new)(void* klass, uintptr_t count);
void* (*il2cpp_method_get_param_name)(void* method, uint32_t index);
char* (*il2cpp_method_get_name)(void* method);
char* (*il2cpp_class_get_name)(void* klass);
void* (*il2cpp_class_get_type)(void* klass);

// Transform methods
Vector3 (*Transform_get_position)(void* transform);
void (*Transform_set_position)(void* transform, Vector3 pos);

// GameObject methods  
void* (*GameObject_get_transform)(void* gameObject);
void* (*GameObject_Find)(void* name);
char* (*GameObject_get_name)(void* gameObject);

// Component methods
void* (*Component_get_transform)(void* component);
void* (*Component_get_gameObject)(void* component);

// Camera
void* (*Camera_get_main)();
Vector3 (*Camera_WorldToScreenPoint)(void* camera, Vector3 worldPos);

// Object
void* (*Object_FindObjectsOfType)(void* type);

// ============================================
// INICIALIZARE IL2CPP
// ============================================

static bool InitializeIL2CPP() {
    void* handle = dlopen("UnityFramework", RTLD_LAZY);
    if (!handle) {
        handle = dlopen(NULL, RTLD_LAZY);
    }
    
    if (!handle) {
        NSLog(@"[ESP] Failed to open UnityFramework");
        return false;
    }
    
    // Load IL2CPP functions
    il2cpp_domain_get = (void* (*)())dlsym(handle, "il2cpp_domain_get");
    il2cpp_domain_get_assemblies = (void* (*)(void*, size_t*))dlsym(handle, "il2cpp_domain_get_assemblies");
    il2cpp_assembly_get_image = (void* (*)(void*))dlsym(handle, "il2cpp_assembly_get_image");
    il2cpp_class_from_name = (void* (*)(void*, const char*, const char*))dlsym(handle, "il2cpp_class_from_name");
    il2cpp_class_get_method_from_name = (void* (*)(void*, const char*, int))dlsym(handle, "il2cpp_class_get_method_from_name");
    il2cpp_class_get_methods = (void* (*)(void*, void**))dlsym(handle, "il2cpp_class_get_methods");
    il2cpp_resolve_icall = (void* (*)(const char*))dlsym(handle, "il2cpp_resolve_icall");
    il2cpp_class_get_name = (char* (*)(void*))dlsym(handle, "il2cpp_class_get_name");
    
    if (!il2cpp_domain_get || !il2cpp_class_from_name) {
        NSLog(@"[ESP] Failed to load IL2CPP functions");
        return false;
    }
    
    // Resolve Unity Engine functions
    Camera_get_main = (void* (*)())il2cpp_resolve_icall("UnityEngine.Camera::get_main");
    Camera_WorldToScreenPoint = (Vector3 (*)(void*, Vector3))il2cpp_resolve_icall("UnityEngine.Camera::WorldToScreenPoint_Injected");
    GameObject_Find = (void* (*)(void*))il2cpp_resolve_icall("UnityEngine.GameObject::Find");
    GameObject_get_name = (char* (*)(void*))il2cpp_resolve_icall("UnityEngine.Object::GetName");
    Component_get_transform = (void* (*)(void*))il2cpp_resolve_icall("UnityEngine.Component::get_transform");
    Component_get_gameObject = (void* (*)(void*))il2cpp_resolve_icall("UnityEngine.Component::get_gameObject");
    Transform_get_position = (Vector3 (*)(void*))il2cpp_resolve_icall("UnityEngine.Transform::get_position_Injected");
    Object_FindObjectsOfType = (void* (*)(void*))il2cpp_resolve_icall("UnityEngine.Object::FindObjectsOfType");
    
    NSLog(@"[ESP] IL2CPP initialized successfully");
    return true;
}

// ============================================
// GĂSEȘTE IMAGINE UNITY
// ============================================

static void* GetUnityImage(const char* imageName) {
    void* domain = il2cpp_domain_get();
    if (!domain) return NULL;
    
    size_t assemblyCount = 0;
    void** assemblies = (void**)il2cpp_domain_get_assemblies(domain, &assemblyCount);
    
    for (size_t i = 0; i < assemblyCount; i++) {
        void* image = il2cpp_assembly_get_image(assemblies[i]);
        if (image) {
            // Try to find the image - you might need to check image name here
            return image;
        }
    }
    
    return NULL;
}

// ============================================
// GĂSEȘTE CLASA PLAYER
// ============================================

static void* FindPlayerClass() {
    void* image = GetUnityImage("Assembly-CSharp");
    if (!image) {
        NSLog(@"[ESP] Failed to get Unity image");
        return NULL;
    }
    
    // Încearcă mai multe nume posibile pentru clasa player
    const char* possibleNames[] = {
        "Player",
        "PlayerController",
        "PlayerManager",
        "Character",
        "CharacterController",
        "NetworkPlayer",
        "GamePlayer",
        NULL
    };
    
    for (int i = 0; possibleNames[i] != NULL; i++) {
        void* klass = il2cpp_class_from_name(image, "", possibleNames[i]);
        if (klass) {
            NSLog(@"[ESP] Found player class: %s", possibleNames[i]);
            return klass;
        }
        
        // Try with common namespaces
        klass = il2cpp_class_from_name(image, "Game", possibleNames[i]);
        if (klass) {
            NSLog(@"[ESP] Found player class: Game.%s", possibleNames[i]);
            return klass;
        }
        
        klass = il2cpp_class_from_name(image, "OneState", possibleNames[i]);
        if (klass) {
            NSLog(@"[ESP] Found player class: OneState.%s", possibleNames[i]);
            return klass;
        }
    }
    
    NSLog(@"[ESP] Could not find player class");
    return NULL;
}

// ============================================
// ESP OVERLAY VIEW
// ============================================

@interface ESPOverlayView : UIView {
    NSTimer *updateTimer;
    void* playerClass;
    void* mainCamera;
}
@property (nonatomic, strong) NSMutableArray *players;
@end

@implementation ESPOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.layer.zPosition = 999999;
        self.players = [NSMutableArray array];
        
        // Find player class
        playerClass = FindPlayerClass();
        
        // Get main camera
        if (Camera_get_main) {
            mainCamera = Camera_get_main();
        }
        
        // Update ESP
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 
                                                      repeats:YES 
                                                        block:^(NSTimer *timer) {
            @try {
                [self scanForPlayers];
                [self setNeedsDisplay];
            } @catch (NSException *e) {
                NSLog(@"[ESP] Error: %@", e);
            }
        }];
        
        NSLog(@"[ESP] Unity ESP initialized");
    }
    return self;
}

- (void)scanForPlayers {
    @try {
        [self.players removeAllObjects];
        
        if (!playerClass || !mainCamera) {
            NSLog(@"[ESP] Missing playerClass or camera");
            return;
        }
        
        // Find all objects of player type
        if (!Object_FindObjectsOfType) return;
        
        void* playerType = il2cpp_class_get_type(playerClass);
        void* playersArray = Object_FindObjectsOfType(playerType);
        
        if (!playersArray) return;
        
        // Iterate through players (this is simplified, actual array handling varies)
        // You'll need to properly iterate through the Il2CppArray
        // For now, this is a placeholder
        
        NSLog(@"[ESP] Scanning for players...");
        
    } @catch (NSException *e) {
        NSLog(@"[ESP] Scan error: %@", e);
    }
}

- (void)drawRect:(CGRect)rect {
    @try {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) return;
        
        // Draw players
        for (NSDictionary *player in self.players) {
            Vector3 worldPos = [[player objectForKey:@"position"] pointerValue] ? *(Vector3*)[[player objectForKey:@"position"] pointerValue] : (Vector3){0,0,0};
            
            if (!mainCamera || !Camera_WorldToScreenPoint) continue;
            
            Vector3 screenPos = Camera_WorldToScreenPoint(mainCamera, worldPos);
            
            // Check if in front of camera
            if (screenPos.z < 0) continue;
            
            // Flip Y coordinate (Unity uses bottom-left origin)
            screenPos.y = rect.size.height - screenPos.y;
            
            CGPoint pos = CGPointMake(screenPos.x, screenPos.y);
            
            if (!CGRectContainsPoint(rect, pos)) continue;
            
            // Draw ESP
            [[UIColor greenColor] setStroke];
            CGContextSetLineWidth(context, 2.0);
            
            // Box
            CGRect box = CGRectMake(pos.x - 25, pos.y - 50, 50, 100);
            CGContextStrokeRect(context, box);
            
            // Line
            CGContextMoveToPoint(context, rect.size.width/2, rect.size.height);
            CGContextAddLineToPoint(context, pos.x, pos.y);
            CGContextStrokePath(context);
            
            // Name
            NSString *name = [player objectForKey:@"name"] ?: @"Player";
            NSDictionary *attrs = @{
                NSFontAttributeName: [UIFont boldSystemFontOfSize:12],
                NSForegroundColorAttributeName: [UIColor whiteColor],
                NSStrokeColorAttributeName: [UIColor blackColor],
                NSStrokeWidthAttributeName: @(-3.0)
            };
            [name drawAtPoint:CGPointMake(pos.x - 20, pos.y - 60) withAttributes:attrs];
        }
        
        // Status
        NSString *status = [NSString stringWithFormat:@"Unity ESP | Players: %lu", (unsigned long)self.players.count];
        [[status drawAtPoint:CGPointMake(10, 40) withAttributes:@{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
            NSForegroundColorAttributeName: [UIColor greenColor]
        }];
        
    } @catch (NSException *e) {
        NSLog(@"[ESP] Draw error: %@", e);
    }
}

- (void)dealloc {
    [updateTimer invalidate];
}

@end

// ============================================
// CONSTRUCTOR
// ============================================

__attribute__((constructor))
static void InitializeUnityESP() {
    NSLog(@"[ESP] Unity dylib loaded");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[ESP] Initializing IL2CPP...");
        
        if (!InitializeIL2CPP()) {
            NSLog(@"[ESP] IL2CPP initialization failed!");
            return;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try {
                UIWindow *window = [UIApplication sharedApplication].keyWindow;
                
                if (@available(iOS 13.0, *)) {
                    for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                        if (scene.activationState == UISceneActivationStateForegroundActive) {
                            window = scene.windows.firstObject;
                            break;
                        }
                    }
                }
                
                if (window) {
                    ESPOverlayView *espOverlay = [[ESPOverlayView alloc] initWithFrame:window.bounds];
                    [window addSubview:espOverlay];
                    [window bringSubviewToFront:espOverlay];
                    
                    // Notification
                    UIView *notification = [[UIView alloc] initWithFrame:CGRectMake(
                        (window.bounds.size.width - 240) / 2, 100, 240, 50
                    )];
                    notification.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
                    notification.layer.cornerRadius = 12;
                    notification.layer.borderWidth = 2;
                    notification.layer.borderColor = [UIColor greenColor].CGColor;
                    
                    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(notification.bounds, 10, 10)];
                    label.text = @"✓ UNITY ESP ACTIVATED";
                    label.textColor = [UIColor greenColor];
                    label.font = [UIFont boldSystemFontOfSize:16];
                    label.textAlignment = NSTextAlignmentCenter;
                    [notification addSubview:label];
                    
                    [window addSubview:notification];
                    [window bringSubviewToFront:notification];
                    
                    NSLog(@"[ESP] Unity ESP activated!");
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.5 animations:^{
                            notification.alpha = 0;
                        } completion:^(BOOL finished) {
                            [notification removeFromSuperview];
                        }];
                    });
                }
            } @catch (NSException *e) {
                NSLog(@"[ESP] Activation error: %@", e);
            }
        });
    });
}
