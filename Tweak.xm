#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <substrate.h>

// ============================================
// DEFINIȚII TEHNICE (Nu modifica aici)
// ============================================

typedef struct Vector3 {
    float x; y; z;
} Vector3;

typedef struct Il2CppArray {
    void* klass;
    void* monitor;
    void* bounds;
    uintptr_t max_length;
    void* vector[0]; 
} Il2CppArray;

// Function pointers
void* (*il2cpp_domain_get_assemblies)(void* domain, size_t* size);
void* (*il2cpp_assembly_get_image)(void* assembly);
void* (*il2cpp_class_from_name)(void* image, const char* namespaze, const char* name);
void* (*il2cpp_domain_get)();
void* (*il2cpp_resolve_icall)(const char* name);
void* (*il2cpp_class_get_type)(void* klass);

Vector3 (*Transform_get_position)(void* transform);
void* (*Component_get_transform)(void* component);
void* (*Camera_get_main)();
Vector3 (*Camera_WorldToScreenPoint)(void* camera, Vector3 worldPos);
void* (*Object_FindObjectsOfType)(void* type);

// ============================================
// INIȚIALIZARE
// ============================================

static bool InitializeIL2CPP() {
    void* handle = dlopen("UnityFramework", RTLD_LAZY);
    if (!handle) handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) return false;

    il2cpp_domain_get = (void* (*)())dlsym(handle, "il2cpp_domain_get");
    il2cpp_domain_get_assemblies = (void* (*)(void*, size_t*))dlsym(handle, "il2cpp_domain_get_assemblies");
    il2cpp_assembly_get_image = (void* (*)(void*))dlsym(handle, "il2cpp_assembly_get_image");
    il2cpp_class_from_name = (void* (*)(void*, const char*, const char*))dlsym(handle, "il2cpp_class_from_name");
    il2cpp_resolve_icall = (void* (*)(const char*))dlsym(handle, "il2cpp_resolve_icall");
    il2cpp_class_get_type = (void* (*)(void*))dlsym(handle, "il2cpp_class_get_type");

    Camera_get_main = (void* (*)())il2cpp_resolve_icall("UnityEngine.Camera::get_main");
    Camera_WorldToScreenPoint = (Vector3 (*)(void*, Vector3))il2cpp_resolve_icall("UnityEngine.Camera::WorldToScreenPoint_Injected");
    Component_get_transform = (void* (*)(void*))il2cpp_resolve_icall("UnityEngine.Component::get_transform");
    Transform_get_position = (Vector3 (*)(void*))il2cpp_resolve_icall("UnityEngine.Transform::get_position_Injected");
    Object_FindObjectsOfType = (void* (*)(void*))il2cpp_resolve_icall("UnityEngine.Object::FindObjectsOfType");

    return (il2cpp_domain_get != NULL);
}

// ============================================
// UI ESP (DESIGNUL TĂU ORIGINAL)
// ============================================

@interface ESPOverlayView : UIView {
    NSTimer *updateTimer;
    void* playerClass;
}
@property (nonatomic, strong) NSMutableArray *playersData;
@end

@implementation ESPOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.playersData = [NSMutableArray array];
        
        // Căutare clasă (folosim Assembly-CSharp pentru OneState)
        void* domain = il2cpp_domain_get();
        size_t size;
        void** assemblies = (void**)il2cpp_domain_get_assemblies(domain, &size);
        void* image = il2cpp_assembly_get_image(assemblies[0]); 
        playerClass = il2cpp_class_from_name(image, "", "Player"); // Ajustează numele dacă e nevoie

        updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
            [self scanPlayers];
        }];
    }
    return self;
}

- (void)scanPlayers {
    [self.playersData removeAllObjects];
    void* camera = Camera_get_main ? Camera_get_main() : NULL;
    if (!camera || !playerClass) return;

    Il2CppArray* objects = (Il2CppArray*)Object_FindObjectsOfType(il2cpp_class_get_type(playerClass));
    if (!objects) return;

    for (uintptr_t i = 0; i < objects->max_length; i++) {
        void* player = objects->vector[i];
        if (!player) continue;
        
        Vector3 worldPos = Transform_get_position(Component_get_transform(player));
        Vector3 sPos = Camera_WorldToScreenPoint(camera, worldPos);

        if (sPos.z > 0) {
            [self.playersData addObject:[NSValue valueWithCGPoint:CGPointMake(sPos.x, self.bounds.size.height - sPos.y)]];
        }
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;

    for (NSValue *val in self.playersData) {
        CGPoint pos = [val CGPointValue];

        // Desenare Box (Stilul tău)
        [[UIColor greenColor] setStroke];
        CGContextSetLineWidth(context, 2.0);
        CGRect box = CGRectMake(pos.x - 25, pos.y - 50, 50, 100);
        CGContextStrokeRect(context, box);

        // Desenare Linie (Snapline)
        CGContextMoveToPoint(context, rect.size.width/2, rect.size.height);
        CGContextAddLineToPoint(context, pos.x, pos.y);
        CGContextStrokePath(context);
    }
}
@end

// ============================================
// CONSTRUCTOR REPARAT (FĂRĂ ERORI)
// ============================================

__attribute__((constructor))
static void InitializeUnityESP() {
    // Așteptăm 15 secunde să se încarce framework-ul jocului
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!InitializeIL2CPP()) return;

        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (window) {
            ESPOverlayView *overlay = [[ESPOverlayView alloc] initWithFrame:window.bounds];
            [window addSubview:overlay];
            [window bringSubviewToFront:overlay];
            
            // Notificare de activare
            UILabel *notif = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, window.bounds.size.width, 40)];
            notif.text = @"ONESTATE ESP LOADED";
            notif.textColor = [UIColor greenColor];
            notif.textAlignment = NSTextAlignmentCenter;
            notif.font = [UIFont boldSystemFontOfSize:18];
            [window addSubview:notif];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [notif removeFromSuperview];
            });
        }
    });
}
