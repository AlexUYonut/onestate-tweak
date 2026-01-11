#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

void patch_by_search(const uint8_t *pattern, size_t pattern_size, uint32_t patch_data, NSString *name) {
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    uintptr_t start_addr = slide + 0x400000; 
    uintptr_t end_addr = start_addr + 0x2000000; // Scanam un interval mai mare (32MB)

    for (uintptr_t addr = start_addr; addr < end_addr; addr++) {
        if (memcmp((void *)addr, pattern, pattern_size) == 0) {
            vm_protect(mach_task_self(), (vm_address_t)addr, sizeof(patch_data), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            memcpy((void *)addr, &patch_data, sizeof(patch_data));
            vm_protect(mach_task_self(), (vm_address_t)addr, sizeof(patch_data), false, VM_PROT_READ | VM_PROT_EXECUTE);
            NSLog(@"[OneState] %@ gasit si activat!", name);
            break; 
        }
    }
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. Scanare ESP (Adresa ta: 0x4804EE)
        uint8_t esp_pattern[] = {0xFF, 0x03, 0x01, 0xD1, 0xF6, 0x57, 0x02, 0xA9}; 
        patch_by_search(esp_pattern, sizeof(esp_pattern), 0xD65F03C0, @"ESP");

        // 2. Scanare AIMBOT (Adresa ta: 0x480555)
        uint8_t aim_pattern[] = {0xF4, 0x4F, 0xBE, 0xA9, 0xFD, 0x7B, 0x01, 0xA9}; 
        patch_by_search(aim_pattern, sizeof(aim_pattern), 0xD65F03C0, @"Aimbot");

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
            message:@"Scanare completa: ESP si Aimbot sunt active!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
