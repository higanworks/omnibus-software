#
# Copyright:: Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "git-windows"
default_version "2.28.0"

license "LGPL-2.1"
# the license file does not ship in the portable git package so pull from the source repo
license_file "https://raw.githubusercontent.com/git-for-windows/git/master/LGPL-2.1"

arch_suffix = windows_arch_i386? ? "32" : "64"
# The Git for Windows project includes a build number in their tagging
# scheme and therefore in the URLs for downloaded releases.
# Occasionally, something goes wrong with a build/release and the "real"
# release of a version has a build number other than 1. And so far, the
# release URLs have not followed a consistent pattern for whether and how
# the build number is included.
# This URL pattern has worked for most releases. If a version has multiple
# builds, set the `source url:` again explicitly to the one appropriate for
# that version's release.
source url: "https://github.com/git-for-windows/git/releases/download/v#{version}.windows.1/PortableGit-#{version}-#{arch_suffix}-bit.7z.exe"

if windows_arch_i386?
  version("2.28.0") { source sha256: "11b854e9246057a22014dbf349adfc160ffa740dba7af0dbd42d642661b2cc7f" }
  version("2.27.0") { source sha256: "8cbe1e3b57eb9d02e92cff12089454f2cf090c02958080d62e199ef8764542d3" }
  version("2.26.2") { source sha256: "e18f75db932ab314263c5f7fca7a9d638df3539629dbf5248a4089beb4e03685" }
  version("2.25.0") { source sha256: "5ad97ff1e806815aa461ab39794e42455f19c9a6ead08ca0e5b8f2bb085214a6" }
  version("2.23.0") { source sha256: "33388028d45c685201490b0c621d2dbfde89d902a7257771f18de9bb37ae1b9a" }
else
  version("2.28.0") { source sha256: "0cd682188b76eeb3a5da3a466d4095d2ccd892e07aae5871c45bf8c43cdb3b13" }
  version("2.27.0") { source sha256: "0fd2218ba73e07e5a664d06e0ce514edcd241a2de0ba29ceca123e7d36aa8f58" }
  version("2.26.2") { source sha256: "dd36f76a815b993165e67ad3cbc8f5b2976e5757a0c808a4a92fb72d1000e1c8" }
  version("2.25.0") { source sha256: "c191542f68e788f614f8a676460281399af0c9d32f19a5d208e9621dd46264fb" }
  version("2.23.0") { source sha256: "501d8be861ebb8694df3f47f1f673996b1d1672e12559d4a07fae7a2eca3afc7" }
end

# The git portable archives come with their own copy of posix related tools
# i.e. msys/basic posix/what-do-you-mean-you-dont-have-bash tools that git
# needs.  Surprising nobody who has ever dealt with this on windows, we ship
# our own set of posix libraries and ported tools - the highlights being
# tar.exe, sh.exe, bash.exe, perl.exe etc.  Since our tools reside in
# embedded/bin, we cannot simply extract git's bin/ cmd/ and lib directories
# into embedded.  So we we land them in embedded/git instead.  Git uses a
# strategy similar to ours when it comes to "appbundling" its binaries.  It has
# a /bin top level directory and a /cmd directory.  The unixy parts of it use
# /bin.  The windowsy parts of it use /cmd.  If you add /cmd to the path, there
# are tiny shim-executables in there that forward your call to the appropriate
# internal binaries with the path and environment reconfigured correctly.
# Unfortunately, they work based on relative directories...  so /cmd/git.exe
# looks for ../bin/git.  If we want delivery-cli or other applications to access
# git binaries without having to add yet another directory to the system path,
# we need to add our own shims (or shim-shims as I like to call them).  These
# are .bat files in embedded/bin - one for each binary in git's /cmd directory -
# that simply call out to git's shim binaries.

build do

  env = with_standard_compiler_flags(with_embedded_path)

  source_7z = "#{project_dir}/PortableGit-#{version}-#{arch_suffix}-bit.7z.exe"
  destination = "#{install_dir}/embedded/git"

  command "#{source_7z} -y"
  sync "PortableGit", "#{windows_safe_path(destination)}", env: env

  block "Create bat files to point to executables under embedded/git/cmd" do
    Dir.glob("#{destination}/cmd/*") do |git_bin|
      ext = File.extname(git_bin)
      base = File.basename(git_bin, ext)
      File.open("#{install_dir}/embedded/bin/#{base}.bat", "w") do |f|
        f.puts "@ECHO OFF"
        f.print "START \"\" " if %w{gitk git-gui}.include?(base.downcase)
        f.puts "\"%~dp0..\\git\\cmd\\#{base}#{ext}\" %*"
      end
    end
  end
end
