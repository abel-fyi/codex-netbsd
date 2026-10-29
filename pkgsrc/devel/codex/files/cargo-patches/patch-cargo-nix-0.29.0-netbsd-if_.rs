--- a/nix-0.29.0/src/net/if_.rs
+++ b/nix-0.29.0/src/net/if_.rs
@@ -65,8 +65,7 @@
                   linux_android,
                   solarish,
                   apple_targets,
-                  target_os = "fuchsia",
-                  target_os = "netbsd"))]
+                  target_os = "fuchsia"))]
         IFF_NOTRAILERS as IflagsType;
         /// Interface manages own routes.
         #[cfg(any(target_os = "dragonfly"))]
