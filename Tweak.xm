#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// Definim functiile originale din OneState
void (*old_GetLocalSpaceAim)(void *instance);
void (*old_WorldToScreen)(void *instance, void *position);

// Functiile noastre care vor rula in loc de cele originale
void new_GetLocalSpaceAim(void *instance) {
    // Logica de Aimbot va fi procesata aici prin hook
    return old_GetLocalSpaceAim(instance);
}

void new_WorldToScreen(void *instance, void *position) {
    // Logica de ESP va fi procesata aici prin hook
    return old_WorldToScreen(instance, position);
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    // Asteptam 60 de secunde pentru stabilitatea serverului
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);

        // [1] Activare Automata AIMBOT (4719957 -> 0x480555)
        MSHookFunction((void *)(slide + 0x480555), (void *)&new_GetLocalSpaceAim, (void **)&old_GetLocalSpaceAim);

        // [2] Activare Automata ESP (4719eee -> 0x4804EE)
        MSHookFunction((void *)(slide + 0x4804EE), (void *)&new_WorldToScreen, (void **)&old_WorldToScreen);

        // Afisam alerta de confirmare dupa 60 de secunde
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
            message:@"S-a scurs un minut. Aimbot & ESP sunt acum Active!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
