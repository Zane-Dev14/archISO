#!/usr/bin/env python3
"""
NeuronOS archinstall post-install hook.
This will run inside the live environment after archinstall has pacstrapped the new system.
It chroots into /mnt and runs /usr/local/bin/neuronos-post-install (which must be present in the installed root).
"""
import subprocess
import sys
from pathlib import Path

def run(cmd):
    print("> " + cmd)
    res = subprocess.run(cmd, shell=True)
    return res.returncode == 0

def main():
    mp = Path("/mnt")
    post_script = mp / "usr" / "local" / "bin" / "neuronos-post-install"
    if post_script.exists():
        print("Found post-install script in target, running via arch-chroot...")
        ok = run(f"arch-chroot /mnt /usr/local/bin/neuronos-post-install")
        if not ok:
            print("Warning: post-install script exited with error", file=sys.stderr)
            return 1
        print("Post-install script completed.")
    else:
        print("No post-install script found at", str(post_script))
        print("Skipping NeuronOS post-install customizations.")
    return 0

if __name__ == '__main__':
    sys.exit(main())
