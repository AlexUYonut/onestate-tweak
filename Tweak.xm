#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

void patch_offset(uintptr_t offset, uint32_t data) {
    uintptr_t address = _dyld_get_image_vmaddr_slide(0) + offset;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(data), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)address, &data, sizeof(data));
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(data), false, VM_PROT_READ | VM_PROT_EXECUTE);
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;

    // Am setat 60 de secunde pentru a permite spawn-ul pe server
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // --- AIMBOT (4719957 -> 0x480555) ---
        patch_offset(0x480555, 0xD65F03C0); 

        // --- ESP (4719eee -> 0x4804EE) ---
        patch_offset(0x4804EE, 0xD2800020); 

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
            message:@"Hacks Activated after 1 minute delay!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
