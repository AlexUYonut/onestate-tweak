#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <dlfcn.h>

// ================= CONFIGURATION =================
float movementSpeed = 7.0f; 
#define SPEED_OFFSET 0x4732ff8 
#define TARGET_FRAMEWORK "UnityFramework"
// =================================================

void patch_memory(uintptr_t address, float value) {
    mach_port_t task = mach_task_self();
    if (address < 0x100000000) return;

    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = PAGE_SIZE;

    kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr == KERN_SUCCESS) {
        *(float*)address = value; 
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

__attribute__((constructor))
static void StartUltraHack() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t baseAddress = 0;
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            const char *name = _dyld_get_image_name(i);
            if (strstr(name, TARGET_FRAMEWORK)) {
                baseAddress = (uintptr_t)_dyld_get_image_header(i);
                break;
            }
        }

        if (baseAddress == 0) baseAddress = (uintptr_t)_dyld_get_image_header(0);

        if (baseAddress > 0) {
            uintptr_t finalAddr = baseAddress + SPEED_OFFSET;
            patch_memory(finalAddr, movementSpeed);

            // TEXT DE CONFIRMARE PE ECRAN
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState PRO" 
                                       message:@"Speed Hack is now ACTIVE (7.0x)" 
                                       preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            // Afiseaza alerta peste interfata jocului
            UIWindow *keyWindow = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        keyWindow = ((UIWindowScene*)scene).windows.firstObject;
                        break;
                    }
                }
            } else {
                keyWindow = [UIApplication sharedApplication].keyWindow;
            }
            [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}
