--- third_party/partition_alloc/src/partition_alloc/shim/allocator_shim_override_libc_symbols.h.orig
+++ third_party/partition_alloc/src/partition_alloc/shim/allocator_shim_override_libc_symbols.h
@@ -25,6 +25,11 @@
 
 #include "partition_alloc/shim/allocator_shim_internals.h"
 
+#if defined(__NetBSD__)
+#define PA_SHIM_NOEXCEPT
+#else
+#define PA_SHIM_NOEXCEPT __THROW
+#endif
 extern "C" {
 
 // WARNING: Whenever a new function is added there (which, surprisingly enough,
@@ -36,51 +41,55 @@
 // intercept calls made by dynamic libraries. See crbug.com/1292206 for such
 // an example.
 
-SHIM_ALWAYS_EXPORT void* malloc(size_t size) __THROW {
+SHIM_ALWAYS_EXPORT void* malloc(size_t size) PA_SHIM_NOEXCEPT {
   return ShimMalloc(size, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void free(void* ptr) __THROW {
+SHIM_ALWAYS_EXPORT void free(void* ptr) PA_SHIM_NOEXCEPT {
   ShimFree(ptr, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void* realloc(void* ptr, size_t size) __THROW {
+SHIM_ALWAYS_EXPORT void* realloc(void* ptr, size_t size) PA_SHIM_NOEXCEPT {
   return ShimRealloc(ptr, size, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void* calloc(size_t n, size_t size) __THROW {
+SHIM_ALWAYS_EXPORT void* calloc(size_t n, size_t size) PA_SHIM_NOEXCEPT {
   return ShimCalloc(n, size, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void cfree(void* ptr) __THROW {
+SHIM_ALWAYS_EXPORT void cfree(void* ptr) PA_SHIM_NOEXCEPT {
   ShimFree(ptr, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void* memalign(size_t align, size_t s) __THROW {
+SHIM_ALWAYS_EXPORT void* memalign(size_t align, size_t s) PA_SHIM_NOEXCEPT {
   return ShimMemalign(align, s, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void* aligned_alloc(size_t align, size_t s) __THROW {
+SHIM_ALWAYS_EXPORT void* aligned_alloc(size_t align, size_t s) PA_SHIM_NOEXCEPT {
   return ShimMemalign(align, s, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void* valloc(size_t size) __THROW {
+SHIM_ALWAYS_EXPORT void* valloc(size_t size) PA_SHIM_NOEXCEPT {
   return ShimValloc(size, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT void* pvalloc(size_t size) __THROW {
+SHIM_ALWAYS_EXPORT void* pvalloc(size_t size) PA_SHIM_NOEXCEPT {
   return ShimPvalloc(size);
 }
 
-SHIM_ALWAYS_EXPORT int posix_memalign(void** r, size_t a, size_t s) __THROW {
+SHIM_ALWAYS_EXPORT int posix_memalign(void** r, size_t a, size_t s) PA_SHIM_NOEXCEPT {
   return ShimPosixMemalign(r, a, s);
 }
 
-SHIM_ALWAYS_EXPORT size_t malloc_size(const void* address) __THROW {
+SHIM_ALWAYS_EXPORT size_t malloc_size(const void* address) PA_SHIM_NOEXCEPT {
   return ShimGetSizeEstimate(address, nullptr);
 }
 
-SHIM_ALWAYS_EXPORT size_t malloc_usable_size(void* address) __THROW {
+#if defined(__NetBSD__)
+SHIM_ALWAYS_EXPORT size_t malloc_usable_size(const void* address) PA_SHIM_NOEXCEPT {
+#else
+SHIM_ALWAYS_EXPORT size_t malloc_usable_size(void* address) PA_SHIM_NOEXCEPT {
+#endif
   return ShimGetSizeEstimate(address, nullptr);
 }
 
