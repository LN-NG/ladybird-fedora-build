# Ladybird for Fedora 44 x86_64

An unofficial, manually maintained build of public Ladybird sources.
No local machine files or personal configuration are part of this repository.

The workflow uses a standard GitHub-hosted Linux runner and a Fedora 44 container.
It builds with Clang and mold, three parallel compile jobs, one link job and no LTO.
The selected upstream revision is pinned in `scripts/build.sh`.

Download the `ladybird-fedora44-x86_64` artifact from a successful Actions run,
extract its tar.gz file and run `./bin/Ladybird` in the extracted directory.
See the included README for Fedora runtime packages.
Artifacts and build logs expire after three days.

Only the build scripts and these instructions are published here.
The workflow does not receive account credentials or repository secrets.
The repository owner, workflow activity and cloud build logs are public.

Upstream: https://github.com/LadybirdBrowser/ladybird
