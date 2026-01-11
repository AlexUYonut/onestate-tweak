#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <dlfcn.h>

// ================= CONFIGURATION =================
// Set to 3.0f as requested (3x normal speed)
float movementSpeed = 3.0f; 

// The offset found in your scanner for UnityEngine.Animator::get_speed
#define SPEED_OFFSET 0x4732ff8 
#define TARGET_FRAMEWORK "UnityFramework"
// =================================================

void patch_memory(uintptr_t address, float value) {
    mach_port_t task = mach_task_self();
    
    if (address < 0x100000000) return;

    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = PAGE_SIZE;

    // Change memory protection to allow writing
    kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (kr == KERN_SUCCESS) {
        // Overwrite the float value at the specific memory address
        *(float*)address = value; 
        
        // Restore memory protection to Read + Execute
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

__attribute__((constructor))
static void StartUltraHack() {
    // 60 seconds delay to ensure Unity is fully loaded
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t baseAddress = 0;
        
        // Locate UnityFramework in memory
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            const char *name = _dyld_get_image_name(i);
            if (strstr(name, TARGET_FRAMEWORK)) {
                baseAddress = (uintptr_t)_dyld_get_image_header(i);
                break;
            }
        }

        // Fallback to main bundle if framework not found
        if (baseAddress == 0) {
            baseAddress = (uintptr_t)_dyld_get_image_header(0);
        }

        if (baseAddress > 0) {
            uintptr_t finalAddr = baseAddress + SPEED_OFFSET;
            patch_memory(finalAddr, movementSpeed);
        }
    });
}
