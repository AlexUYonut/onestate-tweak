#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

// Funcție pentru aplicarea offset-urilor în memoria jocului
void patch_offset(uintptr_t offset, uint32_t data) {
    uintptr_t address = _dyld_get_image_vmaddr_slide(0) + offset;
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(data), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    memcpy((void *)address, &data, sizeof(data));
    vm_protect(mach_task_self(), (vm_address_t)address, sizeof(data), false, VM_PROT_READ | VM_PROT_EXECUTE);
}

%hook UIApplication
- (void)finishedTest:(id)arg1 extraResults:(id)arg2 {
    %orig;
    
    // REPARAT: Cast-ul pentru malloc care bloca build-ul la 4KB
    int len = 1024;
    unsigned char *data = (unsigned char *)malloc(len);
    if (data) {
        memset(data, 0, len);
        free(data);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // --- AIMBOT ACTIVARE (Offset-ul tău) ---
        // Folosim codul de asamblare pentru "MOV W0, #1" sau instrucțiunea ta specifică
        patch_offset(0x1234567, 0xD2800020); 

        // --- ESP ACTIVARE (Offset-ul tău) ---
        patch_offset(0x7654321, 0xD2800020);

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"OneState Ultra" 
            message:@"Aimbot & ESP Activated at Offsets!" 
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
%end
