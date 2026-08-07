{
  claude-code,
  fetchurl,
}:

# Anthropic publishes a signed manifest for every Claude Code release. Version
# 2.1.222 and this Linux x86_64 checksum were verified against the manifest's
# detached signature and Anthropic key fingerprint:
# 31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE.
claude-code.overrideAttrs (_old: {
  version = "2.1.222";
  src = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/2.1.222/linux-x64/claude";
    hash = "sha256-EMqujyK5FcJr//DgE6TUVgjE8a4odYNiZWkVb0R3MOU=";
  };
})
