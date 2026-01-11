#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// Funcție pentru a scrie octeți (bytes) direct în memorie
void patch_memory(uintptr_t address, const char *hex) {
    size_t len = strlen(hex) / 2;
    // Linia corectată pentru a elimina eroarea din log-ul tău
unsigned char *data = (unsigned char *)malloc(len);

    for (size_t i = 0; i < len; i++) {
        sscanf(hex + i * 2, "%02hhx", &data[i]);
    }

    kern_return_t kr;
    mach_port_t task = mach_task_self();
    
    // Deblocăm memoria pentru scriere
    kr = vm_protect(task, (vm_address_t)address, len, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr == KERN_SUCCESS) {
        memcpy((void *)address, data, len);
        // Restaurăm protecția originală (Citire + Execuție)
        vm_protect(task, (vm_address_t)address, len, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
    free(data);
}

// Găsim unde este încărcat UnityFramework în RAM
uintptr_t get_base_address() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "UnityFramework")) {
            return _dyld_get_image_vmaddr_slide(i) + 0x100000000; // ASLR Slide + Base
        }
    }
    return 0;
}

void apply_cheats() {
    uintptr_t base = get_base_address();
    if (base <= 0x100000000) return; 

    // 1. AIMBOT (Offset: 0x47281e3) -> Patch: 20008052C0035FD6
    patch_memory(base + 0x47281e3, "20008052C0035FD6");

    // 2. ESP POSITION (Offset: 0x471d161) -> Patch: 00F0271E0008201EC0035FD6
    patch_memory(base + 0x471d161, "00F0271E0008201EC0035FD6");
    
    // 3. GOD MODE (Offset: 0x462d525) -> Patch: 00E0BF12C0035FD6
    patch_memory(base + 0x462d525, "00E0BF12C0035FD6");
}

%hook UIApplication
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // Așteptăm să se încarce resursele jocului
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_cheats();
        
        // Notificare vizuală că a funcționat
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Mod" 
                                    message:@"Aimbot, ESP și GodMode activate!" 
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Baftă!" style:UIAlertActionStyleDefault handler:nil]];
        [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end



