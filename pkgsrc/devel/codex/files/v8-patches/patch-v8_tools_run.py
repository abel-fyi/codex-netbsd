$NetBSD: patch-v8_tools_run.py,v 1.25 2026/09/02 13:13:40 kikadf Exp $

* Part of patchset to build chromium on NetBSD
* Applies PaX MPROTECT permission to generated V8 tools before execution.

--- v8/tools/run.py.orig
+++ v8/tools/run.py
@@ -8,6 +8,7 @@
 
 import subprocess
 import sys
+import os
 
 from pathlib import Path
 
@@ -21,6 +22,9 @@
   kwargs = dict(stdout=subprocess.PIPE)
   cmd = cmd[2:]
 
+if sys.platform.startswith("netbsd") and cmd and not os.path.isabs(cmd[0]) and os.path.isfile(cmd[0]):
+  subprocess.run(["/usr/sbin/paxctl", "+m", cmd[0]], check=True)
+
 process = subprocess.Popen(cmd, **kwargs)
 stdout, _ = process.communicate()
 if stdout_file:
