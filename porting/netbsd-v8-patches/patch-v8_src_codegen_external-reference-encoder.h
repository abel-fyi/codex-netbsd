$NetBSD: patch-v8_src_codegen_external-reference-encoder.h,v 1.1 2026/10/28 00:00:00 codex Exp $

* NetBSD V8 external reference lookup fallback

--- v8/src/codegen/external-reference-encoder.h.orig
+++ v8/src/codegen/external-reference-encoder.h
@@ -15,6 +15,7 @@
 namespace internal {
 
 class Isolate;
+class ExternalReferenceTable;
 
 class ExternalReferenceEncoder {
  public:
@@ -49,6 +50,7 @@
 
  private:
   AddressToIndexHashMap* map_;
+  ExternalReferenceTable* table_;
 
 #ifdef DEBUG
   mutable std::vector<int> count_;
