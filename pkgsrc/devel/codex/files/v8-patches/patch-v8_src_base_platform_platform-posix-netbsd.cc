--- v8/src/base/platform/platform-posix.cc.orig
+++ v8/src/base/platform/platform-posix.cc
@@ -1515,7 +1515,9 @@
   int error = pthread_getattr_np(pthread_self(), &attr);
 #endif
   if (error) {
+#if !V8_OS_BSD
     DCHECK(MainThreadIsCurrentThread());
+#endif
     return nullptr;
   }
   void* base;
