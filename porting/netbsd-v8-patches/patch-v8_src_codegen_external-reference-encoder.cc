$NetBSD: patch-v8_src_codegen_external-reference-encoder.cc,v 1.1 2026/10/28 00:00:00 codex Exp $

* NetBSD V8 external reference lookup fallback

--- v8/src/codegen/external-reference-encoder.cc.orig
+++ v8/src/codegen/external-reference-encoder.cc
@@ -11,6 +11,7 @@
 namespace internal {
 
 ExternalReferenceEncoder::ExternalReferenceEncoder(Isolate* isolate) {
+  table_ = isolate->external_reference_table();
 #ifdef DEBUG
   api_references_ = isolate->api_external_references();
   if (api_references_ != nullptr) {
@@ -59,7 +60,18 @@
 Maybe<ExternalReferenceEncoder::Value> ExternalReferenceEncoder::TryEncode(
     Address address) const {
   Maybe<uint32_t> maybe_index = map_->Get(address);
-  if (maybe_index.IsNothing()) return Nothing<Value>();
+  if (maybe_index.IsNothing()) {
+#if V8_OS_NETBSD
+    // NetBSD may produce function addresses that the address index misses.
+    // Resolve references against the table used to populate the index.
+    for (uint32_t i = 0; i < ExternalReferenceTable::kSize; ++i) {
+      if (table_->address(i) == address) {
+        return Just<Value>(Value(Value::Encode(i, false)));
+      }
+    }
+#endif
+    return Nothing<Value>();
+  }
   Value result(maybe_index.FromJust());
 #ifdef DEBUG
   if (result.is_from_api()) count_[result.index()]++;
