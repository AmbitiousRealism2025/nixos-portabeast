{
  appimageTools,
  code-cursor,
  fetchurl,
}:

let
  version = "3.15.19";
  appimage = fetchurl {
    url = "https://downloads.cursor.com/production/de07bee81cefe43461ebf4f40c3d2d78d15052aa/linux/x64/Cursor-${version}-x86_64.AppImage";
    hash = "sha256-lSzgIyQgWNg3rOBZ0UMRbWAUHcY2GLuTZYbLHlBwbSY=";
  };
in
code-cursor.overrideAttrs {
  inherit version;

  src = appimageTools.extract {
    pname = "cursor";
    inherit version;
    src = appimage;
  };
  sourceRoot = "cursor-${version}-extracted/usr/share/cursor";
}
