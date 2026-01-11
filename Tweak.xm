#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// ================= CONFIGURATION =================
// 0.2f te face foarte usor (Moon Jump + viteza crescuta la deplasare)
float customValue = 0.2f; 

// Folosim offset-ul de Gravity identificat in scanarea ta (imaginea 4)
#define TARGET_OFFSET 0x472ea59 
#define TARGET_FRAMEWORK "UnityFramework"
// =================================================

void patch_memory(uintptr_t address, float value) {
    mach_port_t task = mach_task_self();
    if (address < 0x100000000) return;

    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = PAGE_SIZE;

    // Metoda PUBG: Schimbam permisiunile paginii pentru scriere directa
    kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr == KERN_SUCCESS) {
        *(float*)address = value; // Injectam valoarea dorita
        
        // Restauram protectia (Read + Execute) pentru a evita detectia
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

__attribute__((constructor))
static void StartUltraHack() {
    // DELAY de 60 secunde (exact cum ai cerut)
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
            patch_memory(baseAddress + TARGET_OFFSET, customValue);
            
            // NOTIFICARE CONFIRMARE (Sa stii cand s-a injectat)
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState PRO" 
                                       message:@"Hack Injectat cu Succes!\nGravity setat la 0.2" 
                                       preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            // Afisare alerta peste joc
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
